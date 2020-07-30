import 'dart:async';
import 'dart:ui';

import 'package:bonfire/bonfire.dart';
import 'package:flame/animation.dart' as FlameAnimation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mountain_fight/custom_player/custom_player.dart';
import 'package:mountain_fight/custom_player/custom_player_extensions.dart';
import 'package:mountain_fight/main.dart';
import 'package:mountain_fight/model/hello.dart';
import 'package:mountain_fight/socket/SocketManager.dart';
import 'package:mountain_fight/util/extensions.dart';

class GamePlayer extends CustomPlayer {
  final Position initPosition;
  final int id;
  final String nick;
  double stamina = 100;
  JoystickMoveDirectional atualDiretional;
  TextConfig _textConfig;
  Timer _timerStamina;
  String lastMove = 'IDLE';

  GamePlayer(this.id, this.nick, this.initPosition, SpriteSheet spriteSheet)
      : super(
          animIdleTop: spriteSheet.createAnimation(0, stepTime: 0.1),
          animIdleBottom: spriteSheet.createAnimation(1, stepTime: 0.1),
          animIdleLeft: spriteSheet.createAnimation(2, stepTime: 0.1),
          animIdleRight: spriteSheet.createAnimation(3, stepTime: 0.1),
          animRunTop: spriteSheet.createAnimation(4, stepTime: 0.1),
          animRunBottom: spriteSheet.createAnimation(5, stepTime: 0.1),
          animRunLeft: spriteSheet.createAnimation(6, stepTime: 0.1),
          animRunRight: spriteSheet.createAnimation(7, stepTime: 0.1),
          width: tileSize * 1.5,
          height: tileSize * 1.5,
          initPosition: initPosition,
          life: 100,
          speed: tileSize * 3,
          collision: Collision(
            height: (tileSize * 0.5),
            width: (tileSize * 0.6),
            align: Offset((tileSize * 0.9) / 2, tileSize),
          ),
          tileSize: tileSize,
        ) {
    _textConfig = TextConfig(
      fontSize: height / 3.5,
    );
  }

  void _verifyStamina() {
    // mana
    if (_timerStamina == null) {
      _timerStamina = Timer(Duration(milliseconds: 150), () {
        _timerStamina = null;
      });
    } else {
      return;
    }

    stamina += 2;
    if (stamina > 100) {
      stamina = 100;
    }
  }

  void decrementStamina(int i) {
    stamina -= i;
    if (stamina < 0) {
      stamina = 0;
    }
  }

  @override
  void update(double dt) {
    if (isDead) return;
    _verifyStamina(); // hồi mana
    super.update(dt);
  }

  @override
  void joystickChangeDirectional(JoystickDirectionalEvent event) {
    if (event.directional != atualDiretional) {
      super.joystickChangeDirectional(event);
    }
  }

  var hello = new HelloObjectBuilder(message: "mmm", name: "same", count: 1);

  void sendPositionToServer(String diretionalEVent) {
    hello.toBytes();

    if (position != null) SocketManager().send('message', hello.toBytes());
  }

  void showEmote(FlameAnimation.Animation emoteAnimation) {
    gameRef.add(
      AnimatedFollowerObject(
        animation: emoteAnimation,
        target: this,
        width: position.width / 2,
        height: position.width / 2,
        positionFromTarget: Position(25, -10),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    _textConfig.withColor(Colors.white).render(
          canvas,
          nick,
          Position(position.left + 2, position.top - 20),
        );
    super.render(canvas);
  }

  @override
  void joystickAction(JoystickActionEvent action) {
    if (gameRef.joystickController.keyboardEnable &&
        action.id == LogicalKeyboardKey.space.keyId) {
      _execAttack();
    }
    if (action.id == 0 && action.event == ActionEvent.DOWN) {
      _execAttack();
    }
    super.joystickAction(action);
  }

  void _execAttack() {
    if (stamina < 25 || isDead) {
      return;
    }
    decrementStamina(25);
    SocketManager().send('message', hello.toBytes());
    var anim = FlameAnimation.Animation.sequenced('axe_spin_atack.png', 8,
        textureWidth: 148, textureHeight: 148, stepTime: 0.05);
    this.simpleAttackRange(
      id: id,
      animationRight: anim,
      animationLeft: anim,
      animationTop: anim,
      animationBottom: anim,
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
    );
  }

  @override
  void receiveDamage(double damage, int from) {
    SocketManager().send('message', hello.toBytes());
    this.showDamage(damage,
        config: TextConfig(color: Colors.red, fontSize: 14));
    super.receiveDamage(damage, from);
  }

  @override
  void die() {
    life = 0;
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

  @override
  void initUpdate() {
    {
      String diretionalEVent = '';
      if (!this.isDead) {
        switch (currentDirectional) {
          case JoystickMoveDirectional.MOVE_UP:
            diretionalEVent = 'UP';
            sendPositionToServer(diretionalEVent);
            customMoveTop();

            break;
          case JoystickMoveDirectional.MOVE_UP_LEFT:
            diretionalEVent = 'UP_LEFT';
            sendPositionToServer(diretionalEVent);
            customMoveUpLeft();

            break;
          case JoystickMoveDirectional.MOVE_UP_RIGHT:
            diretionalEVent = 'UP_RIGHT';
            sendPositionToServer(diretionalEVent);
            customMoveUpRight();

            break;
          case JoystickMoveDirectional.MOVE_RIGHT:
            diretionalEVent = 'RIGHT';
            sendPositionToServer(diretionalEVent);
            customMoveRight();

            break;
          case JoystickMoveDirectional.MOVE_DOWN:
            diretionalEVent = 'DOWN';
            sendPositionToServer(diretionalEVent);
            customMoveBottom();

            break;
          case JoystickMoveDirectional.MOVE_DOWN_RIGHT:
            diretionalEVent = 'DOWN_RIGHT';
            sendPositionToServer(diretionalEVent);
            customMoveDownRight();

            break;
          case JoystickMoveDirectional.MOVE_DOWN_LEFT:
            diretionalEVent = 'DOWN_LEFT';
            sendPositionToServer(diretionalEVent);
            customMoveDownLeft();

            break;
          case JoystickMoveDirectional.MOVE_LEFT:
            diretionalEVent = 'LEFT';
            sendPositionToServer(diretionalEVent);
            customMoveLeft();

            break;
          case JoystickMoveDirectional.IDLE:
            diretionalEVent = 'IDLE';
            if (lastMove == 'IDLE') {
              break;
            } else {
              sendPositionToServer(diretionalEVent);
            }
            idle();

            break;
        }
        lastMove = diretionalEVent;
      }
    }
  }
}
