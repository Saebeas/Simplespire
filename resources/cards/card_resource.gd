class_name CardResource
extends Resource

# =============================================================================
# CardResource — Typed data container for a single card definition.
# =============================================================================
# Created at runtime by DataLoader from balance.json.
# One instance = one unique card type (e.g. "Crystal Golem").
# Duplicate instances in a deck are references to the SAME CardResource.
#
# Role/Rarity enums are defined here — they are card-domain concerns.
# Access from anywhere: CardResource.Role.TANK, CardResource.Rarity.COMMON
# =============================================================================


# -----------------------------------------------------------------------------
# Enums
# -----------------------------------------------------------------------------

enum Role {
	TANK,       ## 0 — High HP, slow, best garrison unit
	MELEE_DPS,  ## 1 — Glass cannon, fast, fragile
	RANGED,     ## 2 — Attacks from distance, moderate HP
	SWARM,      ## 3 — Multiple weak units per card play
	SIEGE,      ## 4 — Bonus damage vs bosses/towers
	BRUISER     ## 5 — Balanced all-rounder
}

enum Rarity {
	COMMON, ## 0 — Pure stats, no effects, cheap backbone
	RARE,   ## 1 — One effect, moderate cost
	EPIC    ## 2 — Powerful effect, expensive, deck-defining
}


# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------
@export var id: String = ""
@export var display_name: String = ""
@export var role: int = Role.BRUISER
@export var rarity: int = Rarity.COMMON

# -----------------------------------------------------------------------------
# Economy
# -----------------------------------------------------------------------------
@export var cost: int = 20   ## Mined Resources required to play this card

# -----------------------------------------------------------------------------
# Unit Stats (applied to every unit spawned by this card)
# -----------------------------------------------------------------------------
@export var hp: int = 100
@export var dps: float = 10.0
@export var attack_range: float = 0.0   ## 0 = melee contact, >0 = ranged pixels
@export var move_speed: float = 120.0

# -----------------------------------------------------------------------------
# Special Behaviour
# -----------------------------------------------------------------------------
@export var spawn_count: int = 1
## How many units this card spawns. 1 = normal, 3+ = swarm.

@export var boss_damage_multiplier: float = 1.0
## Damage dealt to bosses is multiplied by this. Siege cards use 2.0.

# -----------------------------------------------------------------------------
# Art References (placeholder strings until assets exist)
# -----------------------------------------------------------------------------
@export var sprite_id: String = ""
@export var card_art_id: String = ""


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

func get_role_name() -> String:
	return Role.keys()[role]


func get_rarity_name() -> String:
	return Rarity.keys()[rarity]


func get_description() -> String:
	return "[%s] %s | Cost:%d HP:%d DPS:%.1f Range:%.0f Speed:%.0f x%d" % [
		get_rarity_name(),
		display_name,
		cost, hp, dps,
		attack_range,
		move_speed,
		spawn_count
	]
