#!/bin/bash

# Following this article: https://tforgione.fr/posts/ansi-escape-codes/

# Foreground color: \x1B[38;2;R;G;Bm
# Background color: \x1B[48;2;R;G;Bm

export PREFIX_COLOR="\x1b"

# Example: my_fg_color=$(nv_fg_color 250 210 20)
nv_fg_color() {
  echo "${PREFIX_COLOR}[38;2;$1;$2;$3m"
}

# Example: my_bg_color=$(nv_bg_color 250 210 20)
nv_bg_color() {
  echo "${PREFIX_COLOR}[48;2;$1;$2;$3m"
}

# Export functions
export -f nv_fg_color
export -f nv_bg_color

# Remove colors
export NO_COLOR="${PREFIX_COLOR}[0m"

# Foreground colors
ALICE_BLUE=$(nv_fg_color 240 248 255)
ANTIQUE_WHITE=$(nv_fg_color 250 235 215)
AQUA_MARINE=$(nv_fg_color 127 255 212)
AQUA=$(nv_fg_color 0 255 255)
AZURE=$(nv_fg_color 240 255 255)
BEIGE=$(nv_fg_color 245 245 220)
BISQUE=$(nv_fg_color 255 228 196)
BLACK=$(nv_fg_color 0 0 0)
BLANCHED_ALMOND=$(nv_fg_color 255 235 205)
BLUE_VIOLET=$(nv_fg_color 138 43 226)
BLUE=$(nv_fg_color 0 0 255)
BROWN=$(nv_fg_color 165 42 42)
BURLY_WOOD=$(nv_fg_color 222 184 135)
CADET_BLUE=$(nv_fg_color 95 158 160)
CHART_REUSE=$(nv_fg_color 127 255 0)
CHOCOLATE=$(nv_fg_color 210 105 30)
CORAL=$(nv_fg_color 255 127 80)
CORN_FLOWER_BLUE=$(nv_fg_color 100 149 237)
CORN_SILK=$(nv_fg_color 255 248 220)
CRIMSON=$(nv_fg_color 220 20 60)
CYAN=$(nv_fg_color 0 255 255)
DARK_BLUE=$(nv_fg_color 0 0 139)
DARK_CYAN=$(nv_fg_color 0 139 139)
DARK_GOLDEN_ROD=$(nv_fg_color 184 134 11)
DARK_GRAY=$(nv_fg_color 169 169 169)
DARK_GREEN=$(nv_fg_color 0 100 0)
DARK_KHAKI=$(nv_fg_color 189 183 107)
DARK_MAGENTA=$(nv_fg_color 139 0 139)
DARK_OLIVE_GREEN=$(nv_fg_color 85 107 47)
DARK_ORANGE=$(nv_fg_color 255 140 0)
DARK_ORCHID=$(nv_fg_color 153 50 204)
DARK_RED=$(nv_fg_color 139 0 0)
DARK_SALMON=$(nv_fg_color 233 150 122)
DARK_SEA_GREEN=$(nv_fg_color 143 188 143)
DARK_SLATE_BLUE=$(nv_fg_color 72 61 139)
DARK_SLATE_GRAY=$(nv_fg_color 47 79 79)
DARK_TURQUOISE=$(nv_fg_color 0 206 209)
DARK_VIOLET=$(nv_fg_color 148 0 211)
DEEP_PINK=$(nv_fg_color 255 20 147)
DEEP_SKY_BLUE=$(nv_fg_color 0 191 255)
DIM_GRAY=$(nv_fg_color 105 105 105)
DODGER_BLUE=$(nv_fg_color 30 144 255)
FIREBRICK=$(nv_fg_color 178 34 34)
FLORAL_WHITE=$(nv_fg_color 255 250 240)
FOREST_GREEN=$(nv_fg_color 34 139 34)
GAINSBORO=$(nv_fg_color 220 220 220)
GHOST_WHITE=$(nv_fg_color 248 248 255)
GOLD=$(nv_fg_color 255 215 0)
GOLDEN_ROD=$(nv_fg_color 218 165 32)
GRAY=$(nv_fg_color 128 128 128)
GREEN_YELLOW=$(nv_fg_color 173 255 47)
GREEN=$(nv_fg_color 0 128 0)
HONEYDEW=$(nv_fg_color 240 255 240)
HOT_PINK=$(nv_fg_color 255 105 180)
INDIAN_RED=$(nv_fg_color 205 92 92)
INDIGO=$(nv_fg_color 75 0 130)
IVORY=$(nv_fg_color 255 255 240)
KHAKI=$(nv_fg_color 240 230 140)
LAVENDER_BLUSH=$(nv_fg_color 255 240 245)
LAVENDER=$(nv_fg_color 230 230 250)
LAWN_GREEN=$(nv_fg_color 124 252 0)
LEMON_CHIFFON=$(nv_fg_color 255 250 205)
LIGHT_BLUE=$(nv_fg_color 173 216 230)
LIGHT_CORAL=$(nv_fg_color 240 128 128)
LIGHT_CYAN=$(nv_fg_color 224 255 255)
LIGHT_GOLDEN_ROD_YELLOW=$(nv_fg_color 250 250 210)
LIGHT_GRAY=$(nv_fg_color 211 211 211)
LIGHT_GREEN=$(nv_fg_color 144 238 144)
LIGHT_PINK=$(nv_fg_color 255 182 193)
LIGHT_SALMON=$(nv_fg_color 255 160 122)
LIGHT_SEA_GREEN=$(nv_fg_color 32 178 170)
LIGHT_SKY_BLUE=$(nv_fg_color 135 206 250)
LIGHT_SLATE_GRAY=$(nv_fg_color 119 136 153)
LIGHT_STEEL_BLUE=$(nv_fg_color 176 196 222)
LIGHT_YELLOW=$(nv_fg_color 255 255 224)
LIME_GREEN=$(nv_fg_color 50 205 50)
LIME=$(nv_fg_color 0 255 0)
LINEN=$(nv_fg_color 250 240 230)
MAGENTA=$(nv_fg_color 255 0 255)
MAROON=$(nv_fg_color 128 0 0)
MEDIUM_AQUA_MARINE=$(nv_fg_color 102 205 170)
MEDIUM_BLUE=$(nv_fg_color 0 0 205)
MEDIUM_ORCHID=$(nv_fg_color 186 85 211)
MEDIUM_PURPLE=$(nv_fg_color 147 112 219)
MEDIUM_SEA_GREEN=$(nv_fg_color 60 179 113)
MEDIUM_SLATE_BLUE=$(nv_fg_color 123 104 238)
MEDIUM_SPRING_GREEN=$(nv_fg_color 0 250 154)
MEDIUM_TURQUOISE=$(nv_fg_color 72 209 204)
MEDIUM_VIOLET_RED=$(nv_fg_color 199 21 133)
MIDNIGHT_BLUE=$(nv_fg_color 25 25 112)
MINT_CREAM=$(nv_fg_color 245 255 250)
MISTY_ROSE=$(nv_fg_color 255 228 225)
MOCCASIN=$(nv_fg_color 255 228 181)
NAVAJO_WHITE=$(nv_fg_color 255 222 173)
NAVY=$(nv_fg_color 0 0 128)
OLD_LACE=$(nv_fg_color 253 245 230)
OLIVE_DRAB=$(nv_fg_color 107 142 35)
OLIVE=$(nv_fg_color 128 128 0)
ORANGE_RED=$(nv_fg_color 255 69 0)
ORANGE=$(nv_fg_color 255 165 0)
ORCHID=$(nv_fg_color 218 112 214)
PALE_GOLDEN_ROD=$(nv_fg_color 238 232 170)
PALE_GREEN=$(nv_fg_color 152 251 152)
PALE_TURQUOISE=$(nv_fg_color 175 238 238)
PALE_VIOLET_RED=$(nv_fg_color 219 112 147)
PAPAYA_WHIP=$(nv_fg_color 255 239 213)
PEACH_PUFF=$(nv_fg_color 255 218 185)
PERU=$(nv_fg_color 205 133 63)
PINK=$(nv_fg_color 255 192 203)
PLUM=$(nv_fg_color 221 160 221)
POWDER_BLUE=$(nv_fg_color 176 224 230)
PURPLE=$(nv_fg_color 128 0 128)
RED=$(nv_fg_color 255 0 0)
ROSY_BROWN=$(nv_fg_color 188 143 143)
ROYAL_BLUE=$(nv_fg_color 65 105 225)
SADDLE_BROWN=$(nv_fg_color 139 69 19)
SALMON=$(nv_fg_color 250 128 114)
SANDY_BROWN=$(nv_fg_color 244 164 96)
SEA_GREEN=$(nv_fg_color 46 139 87)
SEA_SHELL=$(nv_fg_color 255 245 238)
SIENNA=$(nv_fg_color 160 82 45)
SILVER=$(nv_fg_color 192 192 192)
SKY_BLUE=$(nv_fg_color 135 206 235)
SLATE_BLUE=$(nv_fg_color 106 90 205)
SLATE_GRAY=$(nv_fg_color 112 128 144)
SNOW=$(nv_fg_color 255 250 250)
SPRING_GREEN=$(nv_fg_color 0 255 127)
STEEL_BLUE=$(nv_fg_color 70 130 180)
TAN=$(nv_fg_color 210 180 140)
TEAL=$(nv_fg_color 0 128 128)
THISTLE=$(nv_fg_color 216 191 216)
TOMATO=$(nv_fg_color 255 99 71)
TURQUOISE=$(nv_fg_color 64 224 208)
VIOLET=$(nv_fg_color 238 130 238)
WHEAT=$(nv_fg_color 245 222 179)
WHITE_SMOKE=$(nv_fg_color 245 245 245)
WHITE=$(nv_fg_color 255 255 255)
YELLOW_GREEN=$(nv_fg_color 154 205 50)
YELLOW=$(nv_fg_color 255 255 0)
export ALICE_BLUE
export ANTIQUE_WHITE
export AQUA
export AQUA_MARINE
export AZURE
export BEIGE
export BISQUE
export BLACK
export BLANCHED_ALMOND
export BLUE
export BLUE_VIOLET
export BROWN
export BURLY_WOOD
export CADET_BLUE
export CHART_REUSE
export CHOCOLATE
export CORAL
export CORN_FLOWER_BLUE
export CORN_SILK
export CRIMSON
export CYAN
export DARK_BLUE
export DARK_CYAN
export DARK_GOLDEN_ROD
export DARK_GRAY
export DARK_GREEN
export DARK_KHAKI
export DARK_MAGENTA
export DARK_OLIVE_GREEN
export DARK_ORANGE
export DARK_ORCHID
export DARK_RED
export DARK_SALMON
export DARK_SEA_GREEN
export DARK_SLATE_BLUE
export DARK_SLATE_GRAY
export DARK_TURQUOISE
export DARK_VIOLET
export DEEP_PINK
export DEEP_SKY_BLUE
export DIM_GRAY
export DODGER_BLUE
export FIREBRICK
export FLORAL_WHITE
export FOREST_GREEN
export GAINSBORO
export GHOST_WHITE
export GOLD
export GOLDEN_ROD
export GRAY
export GREEN
export GREEN_YELLOW
export HONEYDEW
export HOT_PINK
export INDIAN_RED
export INDIGO
export IVORY
export KHAKI
export LAVENDER
export LAVENDER_BLUSH
export LAWN_GREEN
export LEMON_CHIFFON
export LIGHT_BLUE
export LIGHT_CORAL
export LIGHT_CYAN
export LIGHT_GOLDEN_ROD_YELLOW
export LIGHT_GRAY
export LIGHT_GREEN
export LIGHT_PINK
export LIGHT_SALMON
export LIGHT_SEA_GREEN
export LIGHT_SKY_BLUE
export LIGHT_SLATE_GRAY
export LIGHT_STEEL_BLUE
export LIGHT_YELLOW
export LIME
export LIME_GREEN
export LINEN
export MAGENTA
export MAROON
export MEDIUM_AQUA_MARINE
export MEDIUM_BLUE
export MEDIUM_ORCHID
export MEDIUM_PURPLE
export MEDIUM_SEA_GREEN
export MEDIUM_SLATE_BLUE
export MEDIUM_SPRING_GREEN
export MEDIUM_TURQUOISE
export MEDIUM_VIOLET_RED
export MIDNIGHT_BLUE
export MINT_CREAM
export MISTY_ROSE
export MOCCASIN
export NAVAJO_WHITE
export NAVY
export OLD_LACE
export OLIVE
export OLIVE_DRAB
export ORANGE
export ORANGE_RED
export ORCHID
export PALE_GOLDEN_ROD
export PALE_GREEN
export PALE_TURQUOISE
export PALE_VIOLET_RED
export PAPAYA_WHIP
export PEACH_PUFF
export PERU
export PINK
export PLUM
export POWDER_BLUE
export PURPLE
export RED
export ROSY_BROWN
export ROYAL_BLUE
export SADDLE_BROWN
export SALMON
export SANDY_BROWN
export SEA_GREEN
export SEA_SHELL
export SIENNA
export SILVER
export SKY_BLUE
export SLATE_BLUE
export SLATE_GRAY
export SNOW
export SPRING_GREEN
export STEEL_BLUE
export TAN
export TEAL
export THISTLE
export TOMATO
export TURQUOISE
export VIOLET
export WHEAT
export WHITE
export WHITE_SMOKE
export YELLOW
export YELLOW_GREEN

# Background colors
BG_ALICE_BLUE=$(nv_bg_color 240 248 255)
BG_ANTIQUE_WHITE=$(nv_bg_color 250 235 215)
BG_AQUA_MARINE=$(nv_bg_color 127 255 212)
BG_AQUA=$(nv_bg_color 0 255 255)
BG_AZURE=$(nv_bg_color 240 255 255)
BG_BEIGE=$(nv_bg_color 245 245 220)
BG_BISQUE=$(nv_bg_color 255 228 196)
BG_BLACK=$(nv_bg_color 0 0 0)
BG_BLANCHED_ALMOND=$(nv_bg_color 255 235 205)
BG_BLUE_VIOLET=$(nv_bg_color 138 43 226)
BG_BLUE=$(nv_bg_color 0 0 255)
BG_BROWN=$(nv_bg_color 165 42 42)
BG_BURLY_WOOD=$(nv_bg_color 222 184 135)
BG_CADET_BLUE=$(nv_bg_color 95 158 160)
BG_CHART_REUSE=$(nv_bg_color 127 255 0)
BG_CHOCOLATE=$(nv_bg_color 210 105 30)
BG_CORAL=$(nv_bg_color 255 127 80)
BG_CORN_FLOWER_BLUE=$(nv_bg_color 100 149 237)
BG_CORN_SILK=$(nv_bg_color 255 248 220)
BG_CRIMSON=$(nv_bg_color 220 20 60)
BG_CYAN=$(nv_bg_color 0 255 255)
BG_DARK_BLUE=$(nv_bg_color 0 0 139)
BG_DARK_CYAN=$(nv_bg_color 0 139 139)
BG_DARK_GOLDEN_ROD=$(nv_bg_color 184 134 11)
BG_DARK_GRAY=$(nv_bg_color 169 169 169)
BG_DARK_GREEN=$(nv_bg_color 0 100 0)
BG_DARK_KHAKI=$(nv_bg_color 189 183 107)
BG_DARK_MAGENTA=$(nv_bg_color 139 0 139)
BG_DARK_OLIVE_GREEN=$(nv_bg_color 85 107 47)
BG_DARK_ORANGE=$(nv_bg_color 255 140 0)
BG_DARK_ORCHID=$(nv_bg_color 153 50 204)
BG_DARK_RED=$(nv_bg_color 139 0 0)
BG_DARK_SALMON=$(nv_bg_color 233 150 122)
BG_DARK_SEA_GREEN=$(nv_bg_color 143 188 143)
BG_DARK_SLATE_BLUE=$(nv_bg_color 72 61 139)
BG_DARK_SLATE_GRAY=$(nv_bg_color 47 79 79)
BG_DARK_TURQUOISE=$(nv_bg_color 0 206 209)
BG_DARK_VIOLET=$(nv_bg_color 148 0 211)
BG_DEEP_PINK=$(nv_bg_color 255 20 147)
BG_DEEP_SKY_BLUE=$(nv_bg_color 0 191 255)
BG_DIM_GRAY=$(nv_bg_color 105 105 105)
BG_DODGER_BLUE=$(nv_bg_color 30 144 255)
BG_FIREBRICK=$(nv_bg_color 178 34 34)
BG_FLORAL_WHITE=$(nv_bg_color 255 250 240)
BG_FOREST_GREEN=$(nv_bg_color 34 139 34)
BG_GAINSBORO=$(nv_bg_color 220 220 220)
BG_GHOST_WHITE=$(nv_bg_color 248 248 255)
BG_GOLD=$(nv_bg_color 255 215 0)
BG_GOLDEN_ROD=$(nv_bg_color 218 165 32)
BG_GRAY=$(nv_bg_color 128 128 128)
BG_GREEN_YELLOW=$(nv_bg_color 173 255 47)
BG_GREEN=$(nv_bg_color 0 128 0)
BG_HONEYDEW=$(nv_bg_color 240 255 240)
BG_HOT_PINK=$(nv_bg_color 255 105 180)
BG_INDIAN_RED=$(nv_bg_color 205 92 92)
BG_INDIGO=$(nv_bg_color 75 0 130)
BG_IVORY=$(nv_bg_color 255 255 240)
BG_KHAKI=$(nv_bg_color 240 230 140)
BG_LAVENDER_BLUSH=$(nv_bg_color 255 240 245)
BG_LAVENDER=$(nv_bg_color 230 230 250)
BG_LAWN_GREEN=$(nv_bg_color 124 252 0)
BG_LEMON_CHIFFON=$(nv_bg_color 255 250 205)
BG_LIGHT_BLUE=$(nv_bg_color 173 216 230)
BG_LIGHT_CORAL=$(nv_bg_color 240 128 128)
BG_LIGHT_CYAN=$(nv_bg_color 224 255 255)
BG_LIGHT_GOLDEN_ROD_YELLOW=$(nv_bg_color 250 250 210)
BG_LIGHT_GRAY=$(nv_bg_color 211 211 211)
BG_LIGHT_GREEN=$(nv_bg_color 144 238 144)
BG_LIGHT_PINK=$(nv_bg_color 255 182 193)
BG_LIGHT_SALMON=$(nv_bg_color 255 160 122)
BG_LIGHT_SEA_GREEN=$(nv_bg_color 32 178 170)
BG_LIGHT_SKY_BLUE=$(nv_bg_color 135 206 250)
BG_LIGHT_SLATE_GRAY=$(nv_bg_color 119 136 153)
BG_LIGHT_STEEL_BLUE=$(nv_bg_color 176 196 222)
BG_LIGHT_YELLOW=$(nv_bg_color 255 255 224)
BG_LIME_GREEN=$(nv_bg_color 50 205 50)
BG_LIME=$(nv_bg_color 0 255 0)
BG_LINEN=$(nv_bg_color 250 240 230)
BG_MAGENTA=$(nv_bg_color 255 0 255)
BG_MAROON=$(nv_bg_color 128 0 0)
BG_MEDIUM_AQUA_MARINE=$(nv_bg_color 102 205 170)
BG_MEDIUM_BLUE=$(nv_bg_color 0 0 205)
BG_MEDIUM_ORCHID=$(nv_bg_color 186 85 211)
BG_MEDIUM_PURPLE=$(nv_bg_color 147 112 219)
BG_MEDIUM_SEA_GREEN=$(nv_bg_color 60 179 113)
BG_MEDIUM_SLATE_BLUE=$(nv_bg_color 123 104 238)
BG_MEDIUM_SPRING_GREEN=$(nv_bg_color 0 250 154)
BG_MEDIUM_TURQUOISE=$(nv_bg_color 72 209 204)
BG_MEDIUM_VIOLET_RED=$(nv_bg_color 199 21 133)
BG_MIDNIGHT_BLUE=$(nv_bg_color 25 25 112)
BG_MINT_CREAM=$(nv_bg_color 245 255 250)
BG_MISTY_ROSE=$(nv_bg_color 255 228 225)
BG_MOCCASIN=$(nv_bg_color 255 228 181)
BG_NAVAJO_WHITE=$(nv_bg_color 255 222 173)
BG_NAVY=$(nv_bg_color 0 0 128)
BG_OLD_LACE=$(nv_bg_color 253 245 230)
BG_OLIVE_DRAB=$(nv_bg_color 107 142 35)
BG_OLIVE=$(nv_bg_color 128 128 0)
BG_ORANGE_RED=$(nv_bg_color 255 69 0)
BG_ORANGE=$(nv_bg_color 255 165 0)
BG_ORCHID=$(nv_bg_color 218 112 214)
BG_PALE_GOLDEN_ROD=$(nv_bg_color 238 232 170)
BG_PALE_GREEN=$(nv_bg_color 152 251 152)
BG_PALE_TURQUOISE=$(nv_bg_color 175 238 238)
BG_PALE_VIOLET_RED=$(nv_bg_color 219 112 147)
BG_PAPAYA_WHIP=$(nv_bg_color 255 239 213)
BG_PEACH_PUFF=$(nv_bg_color 255 218 185)
BG_PERU=$(nv_bg_color 205 133 63)
BG_PINK=$(nv_bg_color 255 192 203)
BG_PLUM=$(nv_bg_color 221 160 221)
BG_POWDER_BLUE=$(nv_bg_color 176 224 230)
BG_PURPLE=$(nv_bg_color 128 0 128)
BG_RED=$(nv_bg_color 255 0 0)
BG_ROSY_BROWN=$(nv_bg_color 188 143 143)
BG_ROYAL_BLUE=$(nv_bg_color 65 105 225)
BG_SADDLE_BROWN=$(nv_bg_color 139 69 19)
BG_SALMON=$(nv_bg_color 250 128 114)
BG_SANDY_BROWN=$(nv_bg_color 244 164 96)
BG_SEA_GREEN=$(nv_bg_color 46 139 87)
BG_SEA_SHELL=$(nv_bg_color 255 245 238)
BG_SIENNA=$(nv_bg_color 160 82 45)
BG_SILVER=$(nv_bg_color 192 192 192)
BG_SKY_BLUE=$(nv_bg_color 135 206 235)
BG_SLATE_BLUE=$(nv_bg_color 106 90 205)
BG_SLATE_GRAY=$(nv_bg_color 112 128 144)
BG_SNOW=$(nv_bg_color 255 250 250)
BG_SPRING_GREEN=$(nv_bg_color 0 255 127)
BG_STEEL_BLUE=$(nv_bg_color 70 130 180)
BG_TAN=$(nv_bg_color 210 180 140)
BG_TEAL=$(nv_bg_color 0 128 128)
BG_THISTLE=$(nv_bg_color 216 191 216)
BG_TOMATO=$(nv_bg_color 255 99 71)
BG_TURQUOISE=$(nv_bg_color 64 224 208)
BG_VIOLET=$(nv_bg_color 238 130 238)
BG_WHEAT=$(nv_bg_color 245 222 179)
BG_WHITE_SMOKE=$(nv_bg_color 245 245 245)
BG_WHITE=$(nv_bg_color 255 255 255)
BG_YELLOW_GREEN=$(nv_bg_color 154 205 50)
BG_YELLOW=$(nv_bg_color 255 255 0)
export BG_ALICE_BLUE
export BG_ANTIQUE_WHITE
export BG_AQUA
export BG_AQUA_MARINE
export BG_AZURE
export BG_BEIGE
export BG_BISQUE
export BG_BLACK
export BG_BLANCHED_ALMOND
export BG_BLUE
export BG_BLUE_VIOLET
export BG_BROWN
export BG_BURLY_WOOD
export BG_CADET_BLUE
export BG_CHART_REUSE
export BG_CHOCOLATE
export BG_CORAL
export BG_CORN_FLOWER_BLUE
export BG_CORN_SILK
export BG_CRIMSON
export BG_CYAN
export BG_DARK_BLUE
export BG_DARK_CYAN
export BG_DARK_GOLDEN_ROD
export BG_DARK_GRAY
export BG_DARK_GREEN
export BG_DARK_KHAKI
export BG_DARK_MAGENTA
export BG_DARK_OLIVE_GREEN
export BG_DARK_ORANGE
export BG_DARK_ORCHID
export BG_DARK_RED
export BG_DARK_SALMON
export BG_DARK_SEA_GREEN
export BG_DARK_SLATE_BLUE
export BG_DARK_SLATE_GRAY
export BG_DARK_TURQUOISE
export BG_DARK_VIOLET
export BG_DEEP_PINK
export BG_DEEP_SKY_BLUE
export BG_DIM_GRAY
export BG_DODGER_BLUE
export BG_FIREBRICK
export BG_FLORAL_WHITE
export BG_FOREST_GREEN
export BG_GAINSBORO
export BG_GHOST_WHITE
export BG_GOLD
export BG_GOLDEN_ROD
export BG_GRAY
export BG_GREEN
export BG_GREEN_YELLOW
export BG_HONEYDEW
export BG_HOT_PINK
export BG_INDIAN_RED
export BG_INDIGO
export BG_IVORY
export BG_KHAKI
export BG_LAVENDER
export BG_LAVENDER_BLUSH
export BG_LAWN_GREEN
export BG_LEMON_CHIFFON
export BG_LIGHT_BLUE
export BG_LIGHT_CORAL
export BG_LIGHT_CYAN
export BG_LIGHT_GOLDEN_ROD_YELLOW
export BG_LIGHT_GRAY
export BG_LIGHT_GREEN
export BG_LIGHT_PINK
export BG_LIGHT_SALMON
export BG_LIGHT_SEA_GREEN
export BG_LIGHT_SKY_BLUE
export BG_LIGHT_SLATE_GRAY
export BG_LIGHT_STEEL_BLUE
export BG_LIGHT_YELLOW
export BG_LIME
export BG_LIME_GREEN
export BG_LINEN
export BG_MAGENTA
export BG_MAROON
export BG_MEDIUM_AQUA_MARINE
export BG_MEDIUM_BLUE
export BG_MEDIUM_ORCHID
export BG_MEDIUM_PURPLE
export BG_MEDIUM_SEA_GREEN
export BG_MEDIUM_SLATE_BLUE
export BG_MEDIUM_SPRING_GREEN
export BG_MEDIUM_TURQUOISE
export BG_MEDIUM_VIOLET_RED
export BG_MIDNIGHT_BLUE
export BG_MINT_CREAM
export BG_MISTY_ROSE
export BG_MOCCASIN
export BG_NAVAJO_WHITE
export BG_NAVY
export BG_OLD_LACE
export BG_OLIVE
export BG_OLIVE_DRAB
export BG_ORANGE
export BG_ORANGE_RED
export BG_ORCHID
export BG_PALE_GOLDEN_ROD
export BG_PALE_GREEN
export BG_PALE_TURQUOISE
export BG_PALE_VIOLET_RED
export BG_PAPAYA_WHIP
export BG_PEACH_PUFF
export BG_PERU
export BG_PINK
export BG_PLUM
export BG_POWDER_BLUE
export BG_PURPLE
export BG_RED
export BG_ROSY_BROWN
export BG_ROYAL_BLUE
export BG_SADDLE_BROWN
export BG_SALMON
export BG_SANDY_BROWN
export BG_SEA_GREEN
export BG_SEA_SHELL
export BG_SIENNA
export BG_SILVER
export BG_SKY_BLUE
export BG_SLATE_BLUE
export BG_SLATE_GRAY
export BG_SNOW
export BG_SPRING_GREEN
export BG_STEEL_BLUE
export BG_TAN
export BG_TEAL
export BG_THISTLE
export BG_TOMATO
export BG_TURQUOISE
export BG_VIOLET
export BG_WHEAT
export BG_WHITE
export BG_WHITE_SMOKE
export BG_YELLOW
export BG_YELLOW_GREEN
