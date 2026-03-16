extends Node

# =============================================================================
# EventBus — Pure Signal Relay Singleton
# Zero game logic. Zero _ready(). Zero _process().
# All cross-system communication routes through this file.
#
# EMIT:   EventBus.signal_name.emit(args)
# LISTEN: EventBus.signal_name.connect(_on_handler)
# ENUMS:  EventBus.Faction.PLAYER  /  EventBus.PlayMode.PUSH
# =============================================================================


# =============================================================================
# SHARED ENUMS
# Defined here so every script imports from ONE source of truth.
# Note: enum types cannot be used as signal param type hints in Godot 4,
#       so enum-backed params are declared as int. Cast at the receiver.
# =============================================================================

enum PlayMode { PUSH, GARRISON }
enum Faction  { PLAYER, ENEMY  }


# =============================================================================
# RESOURCE EVENTS
# =============================================================================

## Emitted when the player successfully harvests a crystal node.
signal resource_mined(amount: int, source: Node)

## Emitted when an enemy creep dies and drops loot at a world position.
signal loot_dropped(amount: int, position: Vector2)

## Emitted by ResourceManager whenever either currency value changes.
## HUD and UI listen to this to refresh displays.
signal resources_changed(mined: int, loot: int)

## Emitted when a spend attempt fails due to insufficient currency.
## type: "mined" or "loot"
signal insufficient_resources(type: String, needed: int, have: int)


# =============================================================================
# UNIT EVENTS
# =============================================================================

## Emitted when any combat unit (minion, creep, boss) is spawned.
signal unit_spawned(entity: Node, type: String)

## Emitted when any combat unit dies.
## killer may be null (e.g. died from AoE or fall damage).
signal unit_died(entity: Node, killer: Node)

## Emitted when a card is confirmed to play as a field minion.
## mode: PlayMode enum value cast to int
signal minion_played(card: Resource, position: Vector2, mode: int)


# =============================================================================
# TOWER EVENTS
# =============================================================================

## Emitted when a tower flips to player control.
signal tower_captured(tower_index: int)

## Emitted when a tower flips back to enemy control.
signal tower_lost(tower_index: int)

## Emitted when a garrison slot is filled or cleared.
signal tower_garrison_changed(tower_index: int, slot: int, minion: Node)

## Emitted when a tower boss dies.
## faction: the Faction enum value (as int) of the boss that died.
signal boss_died(tower_index: int, faction: int)


# =============================================================================
# MINER EVENTS
# =============================================================================

## Emitted when the player purchases and places a miner.
signal miner_purchased(miner: Node, tower_index: int)

## Emitted when a miner flees a lost tower.
## to_tower: tower index of destination, or -1 if fleeing to base.
signal miner_fled(miner: Node, from_tower: int, to_tower: int)


# =============================================================================
# PLAYER EVENTS
# =============================================================================

## Emitted when the player makes contact with an enemy and is stunned.
signal player_stun_started()

## Emitted when the stun timer expires and the player regains control.
signal player_stun_ended()

## Emitted when the player begins channeling a crystal node.
signal channel_started(node: Node)

## Emitted when channeling completes successfully and resources are awarded.
signal channel_completed(node: Node, yield_amount: int, pack_dropped: bool)

## Emitted when channeling is cancelled for any reason (release / range / stun).
signal channel_interrupted(node: Node)


# =============================================================================
# CARD / SUMMONING EVENTS
# =============================================================================

## Emitted when a card is drawn into the player's hand.
signal card_drawn(card: Resource, hand_index: int)

## Emitted when a card is played (either as push or garrison).
## mode: PlayMode enum value cast to int
signal card_played(card: Resource, hand_index: int, mode: int)

## Emitted when a card pack is opened.
## cards: Array of CardResource instances contained in the pack.
signal pack_opened(cards: Array)

## Emitted when the player presses 1–4 to activate a hand slot's reticle.
signal summon_reticle_activated(hand_index: int)

## Emitted when the reticle is dismissed without summoning (right-click / re-press).
signal summon_reticle_cancelled()

## Emitted when the player left-clicks to confirm a summon location.
signal summon_confirmed(card: Resource, position: Vector2)


# =============================================================================
# GAME STATE EVENTS
# =============================================================================

## Emitted by WaveSpawner each time a new creep wave launches.
signal wave_spawned(wave_number: int)

## Emitted when the end boss dies — triggers win screen.
signal level_won()

## Emitted when the player base HP reaches 0 — triggers loss screen.
signal level_lost()
