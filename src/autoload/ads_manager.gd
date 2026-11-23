extends Node

signal rewarded_completed
signal rewarded_failed(reason: String)
signal interstitial_dismissed

var backend: AdsBackend


func _ready() -> void:
	if OS.has_feature("android"):
		backend = AdMobBackend.new()
	else:
		backend = MockAds.new()

	backend.rewarded_completed.connect(_on_rewarded_completed)
	backend.rewarded_failed.connect(_on_rewarded_failed)
	backend.interstitial_dismissed.connect(_on_interstitial_dismissed)
	backend.initialize()


func show_rewarded() -> void:
	backend.show_rewarded()


func show_interstitial() -> void:
	backend.show_interstitial()


func _on_rewarded_completed() -> void:
	rewarded_completed.emit()


func _on_rewarded_failed(reason: String) -> void:
	rewarded_failed.emit(reason)
	push_warning("Rewarded fallido: %s" % reason)


func _on_interstitial_dismissed() -> void:
	interstitial_dismissed.emit()
