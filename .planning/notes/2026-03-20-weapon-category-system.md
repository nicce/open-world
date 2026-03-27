---
date: "2026-03-20 10:00"
promoted: false
---

Add weapon category system: WeaponCategory resource with base_damage and slot type (one_hand/two_hand). WeaponItem gets a category field and damage_override (0 = use category base). hit() calls weapon.get_damage() instead of .damage. Enables global tuning per weapon class and supports future upgrade systems.
