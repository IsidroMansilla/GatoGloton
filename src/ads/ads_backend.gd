class_name AdsBackend
extends RefCounted

signal rewarded_completed
signal rewarded_failed(reason: String)
signal interstitial_dismissed


func initialize() -> void:
	pass


func is_ready() -> bool:
	return false


func show_rewarded() -> void:
	rewarded_failed.emit("not_implemented")


func show_interstitial() -> void:
	pass
