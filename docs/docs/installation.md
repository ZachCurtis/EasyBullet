---
sidebar_position: 2
---

# Installation

## Install using Studio
Download the [EasyBullet.rbxmx](https://github.com/ZachCurtis/EasyBullet/blob/main/EasyBullet.rbxmx) file and drag it into studio

Or grab the [Marketplace model](https://create.roblox.com/marketplace/asset/13513545189/EasyBullet) and insert it via the Toolbox window

## Install using Wally _(Recommended)_
Install [Wally](https://wally.run/install) if you haven't already

To install EasyBullet using wally, add this line to your wally.toml dependencies:
```toml
EasyBullet = "zachcurtis/easybullet@0.4.0"
```
Then run:
```bash
wally install
```

## Install for [Roblox-TS](https://roblox-ts.com/)
Use NPM to install EasyBullet into your Roblox-TS project:
```bash
npm install @rbxts/easybullet
```

## Install from Github
First clone the repository:

```bash
git clone https://github.com/ZachCurtis/EasyBullet
cd EasyBullet
```

### Then use [Rojo](https://rojo.space)

To build EasyBullet into a model, use:

```bash
rojo build -o "EasyBullet.rbxmx" build.project.json
```

To serve EasyBullet into your game, use:
```bash
rojo serve
```

