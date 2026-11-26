class_name MockAds
extends AdsBackend


func initialize() -> void:
	print("[MockAds] backend inicializado")


func is_ready() -> bool:
	return true


func is_interstitial_ready() -> bool:
	return true


func show_rewarded() -> void:
	print("[MockAds] rewarded simulado")
	rewarded_completed.emit()


func show_interstitial() -> void:
	print("[MockAds] interstitial simulado")
	interstitial_dismissed.emit()
