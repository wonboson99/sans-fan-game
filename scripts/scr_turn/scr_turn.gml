function start_enemy_turn() {
    global.fight_active = false;
    global.menu_state = 0;
    global.menu_select = -1;
    global.attack_timer = 0;
    global.blue_drop = false;
    global.soul_mode = 0;

    if (instance_exists(obj_player)) {
        obj_player.visible = true;
        obj_player.x = (global.box_left + global.box_right) / 2;
        obj_player.y = (global.box_top + global.box_bottom) / 2;
        obj_player.grav_v = 0;
        obj_player.slam = false;
        obj_player.slam_wait = 0;
    }

    // 홀수 턴 250프레임(파랑 전환), 짝수 턴 700프레임
    obj_battle_manager.alarm[0] = (global.turn mod 2 == 1) ? 250 : 700;
}

// 중력 방향 변경 + 내리찍기 (같은 방향이어도 찍음)
function change_gravity(_nd) {
    var _same = (_nd == global.grav_dir);
    global.grav_dir = _nd;
    global.last_dir_t = global.attack_timer;

    if (instance_exists(obj_player)) {
        with (obj_player) {
            // 같은 방향이면 그 벽에서 40px 튀어 올라 다시 찍음
            if (_same) {
                switch (global.grav_dir) {
                    case 0: y = global.box_bottom - 8 - 40; break;
                    case 1: y = global.box_top    + 8 + 40; break;
                    case 2: x = global.box_left   + 8 + 40; break;
                    case 3: x = global.box_right  - 8 - 40; break;
                }
            }
            grav_v = 0;
            slam = true;
            slam_wait = 3;
            jump_buffer = 0;
        }
    }
}
