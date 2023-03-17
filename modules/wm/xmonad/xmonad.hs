import XMonad

import XMonad.Util.EZConfig
import XMonad.Util.Ungrab
import XMonad.Util.Loggers

import XMonad.Layout.ThreeColumns

import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP

main :: IO ()
main = xmonad
     . ewmhFullscreen
     . ewmh
     . withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) defToggleStrutsKey
     $ myConfig

xmobarProp config =
  withEasySB (statusBarProp "xmobar" (pure xmobarPP)) toggleStrutsKey config

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

myXmobarPP :: PP
myXmobarPP = def
        { ppSep             = magenta " • "
        , ppTitleSanitize   = xmobarStrip
        , ppCurrent         = wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
        , ppHidden          = white . wrap " " ""
        , ppHiddenNoWindows = lowWhite . wrap " " ""
        , ppUrgent          = red . wrap (yellow "!") (yellow "!")
        , ppOrder           = \[ws, l, _, wins] -> [ws, l, wins]
        , ppExtras          = [logTitles formatFocused formatUnfocused]
        }
      where
        formatFocused   = wrap (white    "[") (white    "]") . magenta . ppWindow
        formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue    . ppWindow

        -- | Windows should have *some* title, which should not not exceed a
        -- sane length.
        ppWindow :: String -> String
        ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

        blue, lowWhite, magenta, red, white, yellow :: String -> String
        magenta  = xmobarColor "#ff79c6" ""
        blue     = xmobarColor "#bd93f9" ""
        white    = xmobarColor "#f8f8f2" ""
        yellow   = xmobarColor "#f1fa8c" ""
        red      = xmobarColor "#ff5555" ""
        lowWhite = xmobarColor "#bbbbbb" ""

-- import XMonad.Util.EZConfig(additionalKeys)

-- main = xmonad $ defaultConfig `additionalKeys`
--        [ ((mod4Mask, xK_Left),  sendMessage $ Go L)
--        , ((mod4Mask, xK_Down),  sendMessage $ Go D)
--        , ((mod4Mask, xK_Up),    sendMessage $ Go U)
--        , ((mod4Mask, xK_Right), sendMessage $ Go R)
--        ]
