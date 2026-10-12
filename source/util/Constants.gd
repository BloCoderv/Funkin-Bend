extends RefCounted
class_name Constants

## Constantes compartilhadas pelos sistemas de jogo e de interface.
const HEALTH_MAX: float = 2.0
const HEALTH_STARTING: float = HEALTH_MAX / 2.0
const HEALTH_MIN: float = 0.0
const HEALTH_SICK_BONUS: float = 1.5 / 100.0 * HEALTH_MAX
const HEALTH_GOOD_BONUS: float = 0.75 / 100.0 * HEALTH_MAX
const HEALTH_BAD_BONUS: float = 0.0
const HEALTH_SHIT_BONUS: float = -1.0 / 100.0 * HEALTH_MAX
const HEALTH_HOLD_BONUS_PER_SECOND: float = 6.0 / 100.0 * HEALTH_MAX
const HEALTH_MISS_PENALTY: float = -4.0 / 100.0 * HEALTH_MAX
const HEALTH_GHOST_MISS_PENALTY: float = -4.0 / 100.0 * HEALTH_MAX
const HEALTH_HOLD_DROP_PENALTY_PER_SECOND: float = 0.0
const HEALTH_HOLD_DROP_PENALTY_MAX: float = 0.0
const SCORE_GHOST_MISS_PENALTY: float = -10.0
const SCORE_HOLD_BONUS_PER_SECOND: float = 250.0
const SCORE_HOLD_DROP_PENALTY_PER_SECOND: float = -125.0
const HOLD_DROP_PENALTY_THRESHOLD_MS: float = 160.0
const JUDGEMENT_BAD_COMBO_BREAK: bool = true
const JUDGEMENT_SHIT_COMBO_BREAK: bool = true
const PIXEL_PER_MS: float = 0.45
const NOTE_SAFE_ZONE: float = 166.0
const NOTE_INVALID_ZONE: float = 180.0
const NOTE_SPAWN_OFFSET: float = 2000.0
const NOTE_ACTIONS: Array[String] = ["note0", "note1", "note2", "note3"]
const STRUMLINE_NOTE_SIZE: float = 150.0
const STRUMLINE_SEPARATION: float = 11.0
const STRUMLINE_DEFAULT_SCALE: float = 0.7
const STRUMLINE_MARGIN: float = 150.0
const STRUMLINE_MANIA: int = 3
const STRUMLINE_Y_MARGIN: float = 104.0
const MIDDLESCROLL_SCALE: float = 0.55
const STRUMLINE_BACKGROUND_MARGIN: float = 16.0
const SING_ANIMS: Array[String] = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
const SING_ANIM_ID: String = "sing"
const SPLASHES_SCALE: float = 1.4
const COLOR_HEALTH_RED: Color = Color(1.0, 0.0, 0.0)
const COLOR_HEALTH_GREEN: Color = Color(102.0 / 255.0, 1.0, 51.0 / 255.0)
