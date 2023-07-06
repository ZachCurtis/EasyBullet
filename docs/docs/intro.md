---
sidebar_position: 1
title: Introduction
sidebar_label: Introduction
---
# EasyBullet

EasyBullet is a simple bullet runtime that handles network replication, network syncing, and adjusts the rendered bullets by client framerate. 

## Features
- Firing a bullet is as easy as `easyBullet:FireBullet(barrelPosition, bulletVelocity)`
- Easily modify EasyBullet's behavior using an extensive settings table
- Callbacks to override EasyBullet's behavior entirely when the settings table doesn't offer enough
- Accounts for network latency using client's ping
- Projectile modeling using kinematic equations