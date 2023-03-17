import XMonad

import XMonad.Util.EZConfig
import XMonad.Util.Ungrab

import XMonad.Layout.ThreeColumns

import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP

main :: IO ()
main = xmonad $ ewmhFullscreen $ ewmh $ xmobarProp $ myConfig

myConfig = def
    { terminal    = "alacritty"
    , modMask     = mod4Mask
    , borderWidth = 2
    , layoutHook  = myLayout                -- Custom layout
    }
    `additionalKeysP`
    [ ("M-C-s", unGrab *> spawn "scrot -s")
    ]

myLayout = tiled ||| Mirror tiled ||| Full ||| threeCol
  where
    threeCol = ThreeColMid nmaster delta ratio
    tiled    = Tall nmaster delta ratio
    nmaster  = 1      -- Default number of windows in the master pane
    ratio    = 1/2    -- Default proportion of screen occupied by master pane
    delta    = 3/100  -- Percent of screen to increment by when resizing panes

-- import XMonad.Util.EZConfig(additionalKeys)

-- main = xmonad $ defaultConfig `additionalKeys`
--        [ ((mod4Mask, xK_Left),  sendMessage $ Go L)
--        , ((mod4Mask, xK_Down),  sendMessage $ Go D)
--        , ((mod4Mask, xK_Up),    sendMessage $ Go U)
--        , ((mod4Mask, xK_Right), sendMessage $ Go R)
--        ]
