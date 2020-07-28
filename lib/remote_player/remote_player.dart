import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flame/animation.dart' as FlameAnimation;
import 'package:flutter/material.dart';
import 'package:mountain_fight/main.dart';
import 'package:mountain_fight/socket/SocketManager.dart';
import 'package:mountain_fight/util/buffer_delay.dart';
import 'package:mountain_fight/util/extensions.dart';

class RemotePlayer extends SimpleEnemy {
  static const REDUCTION_SPEED_DIAGONAL = 0.7;
  final int id;
  final String nick;

  double lastPositionX;

  double lastPositionY;

  String currentMove = 'IDLE';

  TextConfig _textConfig;
  int idleTime = 0;
  BufferDelay _buffer;

  RemotePlayer(
      this.id, this.nick, Position initPosition, SpriteSheet spriteSheet)
      : super(
          initPosition: initPosition,
          width: tileSize * 1.5,
          height: tileSize * 1.5,
          animIdleTop: spriteSheet.createAnimation(0, stepTime: 0.1),
          animIdleBottom: spriteSheet.createAnimation(1, stepTime: 0.1),
          animIdleLeft: spriteSheet.createAnimation(2, stepTime: 0.1),
          animIdleRight: spriteSheet.createAnimation(3, stepTime: 0.1),
          animRunTop: spriteSheet.createAnimation(4, stepTime: 0.1),
          animRunBottom: spriteSheet.createAnimation(5, stepTime: 0.1),
          animRunLeft: spriteSheet.createAnimation(6, stepTime: 0.1),
          animRunRight: spriteSheet.createAnimation(7, stepTime: 0.1),
          life: 100,
          speed: tileSize * 3,
          collision: Collision(
            height: (tileSize * 0.5),
            width: (tileSize * 0.6),
            align: Offset((tileSize * 0.9) / 2, tileSize),
          ),
        ) {
    lastPositionX = position.left;
    lastPositionY = position.right;
    _buffer = BufferDelay(0);
    _buffer.listen(_listenBuffer);
    _textConfig = TextConfig(
      fontSize: height / 3.5,
    );
    SocketManager().listen('message', (data) {
      String action = data['action'];
      if (action != 'PLAYER_LEAVED' && data['time'] != null) {
        _buffer.add(
          data,
          DateTime.parse(
            data['time'].toString(),
          ),
        );
      }

      if (action == 'RECEIVED_DAMAGE') {
        if (!isDead) {
          double damage = double.parse(data['data']['damage'].toString());
          this.showDamage(damage,
              config: TextConfig(color: Colors.red, fontSize: 14));
          if (life > 0) {
            life -= damage;
            if (life <= 0) {
              die();
            }
          }
        }
      }

      if (action == 'PLAYER_LEAVED' && data['data']['id'] == id) {
        if (!isDead) {
          die();
        }
      }
    });
  }

  @override
  void update(double dt) {
    if (currentMove != 'IDLE') {
      _drawAni();
    } else {
      if (idleTime == 0) {
        this.idle();
        idleTime = 1;
      }
    }
    super.update(dt);
  }

  void drawAnimation(move) {
    switch (move) {
      case 'LEFT':
        animation = animRunLeft;
        lastDirection = Direction.left;
        idleTime = 0;
        break;
      case 'RIGHT':
        animation = animRunRight;
        lastDirection = Direction.right;
        idleTime = 0;
        break;
      case 'UP_RIGHT':
        animation = animRunTopRight;
        lastDirection = Direction.topRight;
        idleTime = 0;
        break;
      case 'DOWN_RIGHT':
        animation = animRunBottomRight;
        lastDirection = Direction.bottomRight;
        idleTime = 0;
        break;
      case 'DOWN_LEFT':
        animation = animRunBottomLeft;
        lastDirection = Direction.bottomLeft;
        idleTime = 0;
        break;
      case 'UP_LEFT':
        animation = animRunTopLeft;
        lastDirection = Direction.topLeft;
        idleTime = 0;
        break;
      case 'UP':
        animation = animRunTop;
        lastDirection = Direction.top;
        idleTime = 0;
        break;
      case 'DOWN':
        animation = animRunBottom;
        lastDirection = Direction.bottom;
        idleTime = 0;
        break;
      case 'IDLE':
        print('vào idle mà chả thể làm mẹ gì cả !!');
        idleTime = 1;
        this.idle();
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (this.isVisibleInCamera()) {
      _textConfig.withColor(Colors.white).render(
            canvas,
            nick,
            Position(position.left + 2, position.top - 20),
          );
      this.drawDefaultLifeBar(canvas, strokeWidth: 4, padding: 0);
    }

    super.render(canvas);
  }

  @override
  void die() {
    gameRef.add(
      AnimatedObjectOnce(
        animation: FlameAnimation.Animation.sequenced(
          "smoke_explosin.png",
          6,
          textureWidth: 16,
          textureHeight: 16,
        ),
        position: position,
      ),
    );
    gameRef.addGameComponent(
      GameDecoration.sprite(
        Sprite('crypt.png'),
        initPosition: Position(
          position.left,
          position.top,
        ),
        height: 30,
        width: 30,
      ),
    );
    remove();
    super.die();
  }

  void _listenBuffer(data) {
    String action = data['action'];
    if (data['data']['player_id'] == id) {
      if (action == 'MOVE') {
        currentMove = data['data']['direction'].toString();
        lastPositionX =
            double.parse(data['data']['position']['x'].toString()) * tileSize;
        lastPositionY =
            double.parse(data['data']['position']['y'].toString()) * tileSize;
        print("update tọa độ x = $lastPositionX và y = $lastPositionY");
        print("move hướng lào đó $currentMove !!");
        _exeMovement(data['data']);
      }
      if (action == 'ATTACK') {
        _execAttack(data['data']['direction']);
      }
    }
  }

  void _exeMovement(data) {
    _correctPosition(data);
    currentMove = data['direction'];
    if (currentMove == 'IDLE') {
      _buffer.reset();
    }
  }

  void _drawAni() {
//    if(position.left- lastPositionX==0 && position.right - lastPositionY ==0){
//      currentMove ='IDLE';
//    }
    drawAnimation(currentMove);
    position = Rect.fromLTWH(
      lastPositionX,
      lastPositionY,
      position.width,
      position.height,
    );
    print("call draw again function x = $lastPositionX và y = $lastPositionY");
  }

  void _correctPosition(data) {
    double positionX =
        double.parse(data['position']['x'].toString()) * tileSize;
    double positionY =
        double.parse(data['position']['y'].toString()) * tileSize;
    Rect newP = Rect.fromLTWH(
      positionX,
      positionY,
      position.width,
      position.height,
    );
    Point p = Point(newP.center.dx, newP.center.dy);
    double dist = p.distanceTo(Point(
      position.center.dx,
      position.center.dy,
    ));

    if (dist > (tileSize * 0.5)) {
      position = newP;
    }
  }

  void _execAttack(String direction) {
    var anim = FlameAnimation.Animation.sequenced(
      'axe_spin_atack.png',
      8,
      textureWidth: 148,
      textureHeight: 148,
      stepTime: 0.05,
    );
    this.simpleAttackRange(
      id: id,
      animationRight: anim,
      animationLeft: anim,
      animationTop: anim,
      animationBottom: anim,
      interval: 0,
      direction: direction.getDirectionEnum(),
      animationDestroy: FlameAnimation.Animation.sequenced(
        "smoke_explosin.png",
        6,
        textureWidth: 16,
        textureHeight: 16,
      ),
      width: tileSize * 0.9,
      height: tileSize * 0.9,
      speed: speed * 1.5,
      damage: 15,
      collision: Collision(
        width: tileSize * 0.9,
        height: tileSize * 0.9,
      ),
      collisionOnlyVisibleObjects: false,
    );
  }

  @override
  void receiveDamage(double damage, int from) {}
}
