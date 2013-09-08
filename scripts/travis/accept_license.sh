#!/usr/bin/env expect -f
#from https://github.com/kokoabim/iOSOpenDev-Installer/issues/1
set timeout -1
spawn sudo xcodebuild -license

expect {
    "Password"
    {
        stty -echo
        expect_user -re "(.*)\n"
        stty echo
        set pass $expect_out(1,string)
        send -- "$pass\r"
        exp_continue
    }
    "incorrect password attempts"
    {
        exit 1
    }
    "Hit the Enter key to view the license agreements"
    {
        send "\r"
        exp_continue
    }
    "Press 'space' for more"
    {
        send " "
        exp_continue
    }
    "By typing 'agree'"
    {
        send "agree\r"
        exp_continue
    }
}
