# Tower Storm

## Moddable Multiplayer Tower Defense

v0.1.0

## Overview

Tower Storm is a Multiplayer Tower Attack and Defense development kit that makes it easy for you to build the Tower Defense game you've always wanted to play. Have you played Tower Defense games in the past and felt they always looked the same? Just a few basic towers that shoot, maybe one that does AOE damage and that's it. Or perhaps you are a fan of the Tower Defense maps in Warcraft 3 or Starcraft with their amazing depth and variety, and want more of that. 

With Tower Storm you can go nuts creating the awesome ideas you've had, and it's completely free and open source. 

## Getting Started

You can either create a copy of this project on [Cloud9](c9.io) or clone these files to a server or your computer and run from there. 

## Pre-requisites

- nodejs >= v4
- npm >= v2

## Running development

- `./init.sh` - This sets up the RethinkDB database, currently Debian/Ubuntu only. 
- `npm install`
- `npm install --global gulp-cli webpack`
- `gulp dist`
- `webpack`
- `npm start`

### Running in Cloud9

- Make your application public by click on `Share` in the top right and ticking the public box beside application. This must be done so bots can connect correctly.
- Click Preview -> Preview running application from the top navigation bar

### Running on your desktop

- Add the line `127.0.0.1   ts.dev` to your `/etc/hosts` file.
- Go to `ts.dev:8080` in your browser. 

## Running in production

You'll need to do the following steps to setup a production server for towerstorm

- Create a towerstorm user
- Install node v4.x and npm v2 (I recommend using nvm)
- Install git
- Extract Tower Storm files to the towerstorm user home dir (or a game folder)
- Add towerstorm user to syslog group so they can write to /var/log
- Setup environment variables mentioned in section below
- `./init.sh`
- `npm run prod`


## Environment variables

These are all optional

- HOSTNAME - The hostname or url of your server, defaults to `ts.dev` if it's not set which is only useful for development.
- COOKIE_SECRET - Secret key used for encrypting login cookies
- DD_API_KEY - For sending your server metrics to Datadog
- DD_APP_KEY - For sending your server metrics to Datadog




## Modifying Tower Storm

If you just want to modify the gameplay or create your own minions/towers/maps etc you only need to pay attention to 2 folders:

- `/config` - This folder contains JSON files describing things in the game world. You'll notice there are subfolders of minions, towers and maps, you can put new creations in there and they'll automatically be loaded by the game. 
- `/frontend/assets` - This is where graphics go for minions/towers/maps.

### Config files

All of the minion/tower/bullet config is stored in the `./config` folder. When you modify these files you only need to refresh the page to see them in action.

### Game code 

When modifying any code in the `/game` folder you need to run webpack to recompile it:

```
webpack
```

### Frontend code

When modifying any coffee-script code in the `/frontend` folder you need to run gulp to rebuild it:

```
gulp frontend
```

### Modifying other code

When modifying code in `/botmanager`,  `/database`, `/gameserver`, `/logger` or `/lobby` you need to restart the nodejs server to reload it (press `ctrl + c` to kill then run `npm start` again)

## Changelog

0.1.0 - First release

## Versioning / Mod compatability

While Tower Storm is in alpha (before 1.0 release) a minor release (0.1.3 -> 0.2) signifies a breaking change and your mods may stop working, a patch release (0.1.1 -> 0.1.2) is a backwards compatible release.

## Known issues

### Bots aren't automatically joining my game

If you're running on Cloud9 make sure you've made your application public via clicking on `Share` in the top right and ticking the box beside `Application`. This needs to be done because bots currently use the public app to authenticate themselves. 

## FAQ

### This is a lot of code without any commit history, where did it all come from?

I started on Tower Storm back in 2013 because I wanted a Tower Defense game that was:

1. Multiplayer 
2. Easy to play, with no software required
3. More in depth than anything out there. 

This turned out to be a far bigger project than I had anticipated and after 3 years of part time development I gave up on the project. 

But of course that desire for an in depth multiplayer tower defense game never went away and still no company has made it happen. So I decided to take the source code for Tower Storm, clean it up and open source it as basically a Tower Defense dev kit that anyone can use to build their own awesome TD games. 

This way everyone can create and play the game they always wanted and I don't have to build this all by myself.

### Why is the design so boostrappy / bland?

Most of the UI assets in Tower Storm were purchased, and these licenses are for a single closed source product only, so I had to change all the UI prior to open sourcing. I want to improve it over time, but wanted to get this game out there first. 

### Why is there no sound / music?

As above most of the sound / music in Tower Storm was purchased and so couldn't be open sourced. I'd like to re-implement SFX and music in the future. 

### Why Angular 1?

When I first started building the frontend in 2013 Angular 1 was the new hotness. I'd like to refactor it to use React but that's a big process and this works for now. 

## Future Plans

- In depth documentation on modding
- Move all game information out of config and into `/mods` folder so that modifications are namespaced and easily distributable
- Re-organize tests and get them all working again
- Convert code from coffeescript to es6 
- Add user accounts / friends back in (the backend code is there, just need frontend recreated)