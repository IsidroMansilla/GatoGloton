class_name AdMobBackend
extends AdsBackend

const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"

var _ready: bool = false
var _rewarded_ad: RewardedAd
var _interstitial_ad: InterstitialAd


func initialize() -> void:
	var request := ConsentRequestParameters.new()
	request.tag_for_under_age_of_consent = false
	UserMessagingPlatform.consent_information.update(
		request,
		_on_consent_updated,
		_on_consent_update_failed,
	)


func is_ready() -> bool:
	return _ready


func is_interstitial_ready() -> bool:
	return _interstitial_ad != null


func show_rewarded() -> void:
	if _rewarded_ad == null:
		rewarded_failed.emit("rewarded_not_ready")
		return
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_reward: RewardedItem) -> void:
		rewarded_completed.emit()
	_rewarded_ad.show(listener)


func show_interstitial() -> void:
	if _interstitial_ad == null:
		interstitial_dismissed.emit()
		return
	_interstitial_ad.show()


func _on_consent_updated() -> void:
	var information := UserMessagingPlatform.consent_information
	if information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		if not information.get_is_consent_form_available():
			push_warning("UMP requiere consentimiento pero no hay formulario disponible")
			return
		UserMessagingPlatform.load_consent_form(_on_consent_form_loaded, _on_consent_form_failed)
		return
	_initialize_mobile_ads()


func _on_consent_update_failed(form_error: FormError) -> void:
	push_warning("UMP no pudo actualizar el consentimiento: %s" % form_error.message)


func _on_consent_form_loaded(form: ConsentForm) -> void:
	form.show(_on_consent_form_dismissed)


func _on_consent_form_failed(form_error: FormError) -> void:
	push_warning("UMP no pudo cargar el formulario: %s" % form_error.message)


func _on_consent_form_dismissed(form_error: FormError) -> void:
	if form_error != null:
		push_warning("UMP cerro el formulario con error: %s" % form_error.message)
		return
	_initialize_mobile_ads()


func _initialize_mobile_ads() -> void:
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_mobile_ads_initialized
	MobileAds.initialize(listener)


func _on_mobile_ads_initialized(_status: InitializationStatus) -> void:
	_ready = true
	_load_rewarded()
	_load_interstitial()


func _load_rewarded() -> void:
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
		_rewarded_ad = null
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_ad = ad
		ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
			ad.destroy()
			_rewarded_ad = null
			_load_rewarded()
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		rewarded_failed.emit(error.message)
	RewardedAdLoader.new().load(TEST_REWARDED_ID, AdRequest.new(), callback)


func _load_interstitial() -> void:
	if _interstitial_ad != null:
		_interstitial_ad.destroy()
		_interstitial_ad = null
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_ad = ad
		ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
			ad.destroy()
			_interstitial_ad = null
			_load_interstitial()
			interstitial_dismissed.emit()
		ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
			push_warning("Interstitial no se pudo mostrar: %s" % error.message)
			ad.destroy()
			_interstitial_ad = null
			_load_interstitial()
			interstitial_dismissed.emit()
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("Interstitial no disponible: %s" % error.message)
	InterstitialAdLoader.new().load(TEST_INTERSTITIAL_ID, AdRequest.new(), callback)
