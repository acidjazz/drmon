
![](examples/2.jpg)
> *status*: currently stable, writing documentation


# drmon
monitor and failsafe automation for your draconic reactor

### what is this
this is a computercraft LUA script that monitors everything about a draconic reactor, with a couple features to help keep it from exploding

### features
* uses a 3x3 advanced computer monitor to display all the stats of your reactor
* regulates the input gate for the targeted field strength of 50%
  * adjustable
* immediate shutdown and charge upon your field strength going below 20%
  * adjustable
  * reactor will activate upon a successful charge
* immediate shutdown when your temperature goes above 8000C
  * adjustable
  * reactor will activate upon temperature cooling down to 3000C
    * adjustable

* easily tweak your output flux gate via touchscreen
  * +/-100k, 10k, and 1k increments

### requirements
* one fully setup draconic reactor with fuel
* 1 advanced computer
* 9 advanced monitors
* 3 wired modems, wireless will not work
* a bunch of network cable

### installation
* your reactor output flux gate must be setup so that one side of it and one of your stabilizers touches a side of the advanced computer
* by default, flux gate should touch the right side, stabilizer should touch the back of the computer
  * if you want to use different sides you need to modify `startup` after you have installed this and specify the sides
* connect a modem to your input flux gate (the one connected to your reactor energy injector)
* connect a modem to your advanced computer
* setup yoru monitors to be a 3x3 and connect a modem to anywhere but the front
* run network cable to all 3 modems
* install this code via running the install script using these commands :

```
> pastebin get Ls1Wg3QQ install
> install
```
* modify `startup` if you wish to configure/alter any variables mentioned in the feature list, you'll find them at the top of the file
```
> startup
```
* you should see stats in your term, and on your monitor

### upgrading to the latest version
* right click your computer
* hold ctrl+t until you get a `>`

```
> install
> startup
```

### known issues
* there is a problem with **skyfactory 2.5** and **pastebin**, see workarounds [here](https://github.com/acidjazz/drmon/issues/9#issuecomment-277910288)
