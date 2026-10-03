// F4 / F11: 전체 화면
if (keyboard_check_pressed(vk_f4) || keyboard_check_pressed(vk_f11)) {
    window_set_fullscreen(!window_get_fullscreen());
}

// ======================================================
// 1. 배틀박스 목표 크기 설정 및 보간 (Lerp)
// ======================================================
var _target_left, _target_right, _target_top, _target_bottom;

if (global.fight_active) {
    _target_left   = 320 - (562 / 2);
    _target_right  = 320 + (562 / 2);
    _target_top    = 295 - (128 / 2);
    _target_bottom = 295 + (128 / 2);
} else if (global.menu_select >= 0 && global.menu_state > 0) {
    _target_left   = 320 - 250;
    _target_right  = 320 + 250;
    _target_top    = 295 - 70;
    _target_bottom = 295 + 70;
} else {
    _target_left   = 320 - 70;
    _target_right  = 320 + 70;
    _target_top    = 295 - 70;
    _target_bottom = 295 + 70;
}

global.box_left   = lerp(global.box_left,   _target_left,   0.2);
global.box_right  = lerp(global.box_right,  _target_right,  0.2);
global.box_top    = lerp(global.box_top,    _target_top,    0.2);
global.box_bottom = lerp(global.box_bottom, _target_bottom, 0.2);

// ======================================================
// 2. 공격 바 스프라이트 스케일 계산
// ======================================================
var _box_w = global.box_right - global.box_left;
var _box_h = global.box_bottom - global.box_top;

var _target_scale_x = max(0.1, (_box_w - 12) / sprite_get_width(spr_fight_bg));
var _target_scale_y = max(0.1, (_box_h - 12) / sprite_get_height(spr_fight_bg));

if (!variable_global_exists("fight_bg_xscale")) global.fight_bg_xscale = 1;
if (!variable_global_exists("fight_bg_yscale")) global.fight_bg_yscale = 1;

global.fight_bg_xscale = lerp(global.fight_bg_xscale, _target_scale_x, 0.2);
global.fight_bg_yscale = lerp(global.fight_bg_yscale, _target_scale_y, 0.2);

// ======================================================
// 3. FIGHT 상태 처리
// ======================================================
if (global.fight_active) {
    var _half_w = sprite_get_width(spr_fight_bg) / 2;
    var _right_x = global.fight_center_x + _half_w;

    if (!global.fight_stopped) {
        global.fight_cursor_x += 8;

        if (global.fight_cursor_x > _right_x) {
            global.fight_damage = 0;
            global.fight_stopped = true;
            alarm[2] = 30;
        }

        if (keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter)) {
            var _dist = abs(global.fight_cursor_x - global.fight_center_x);
            var _ratio = 1 - (_dist / _half_w);
            global.fight_damage = floor(_ratio * 100);
            global.enemy_hp = max(0, global.enemy_hp - global.fight_damage);
            global.fight_stopped = true;
            alarm[2] = 45;
        }
    }
}
// ======================================================
// 4. 적 공격 턴 처리 (패턴 실행)
// ======================================================
else if (global.menu_select == -1) {
    global.attack_timer += 1;
    
    // 현재 턴에 맞는 패턴 실행
    update_attack_pattern();
    
    // 공격 턴 종료 조건: 180프레임 이상 경과
    if (global.attack_timer >= 180) {
        // 모든 공격 객체 정리
        with (obj_bonefield) instance_destroy();
        with (obj_bone) instance_destroy();
        with (obj_blaster) instance_destroy();
        
        // 플레이어 상태 리셋
        if (instance_exists(obj_player)) {
            obj_player.grav_v = 0;
            obj_player.slam = false;
            obj_player.slam_wait = 0;
        }
        
        // 턴 전환
        global.turn += 1;
        global.menu_select = 0;
        global.menu_state = 0;
        global.attack_timer = 0;
        global.blue_drop = false;
        global.soul_mode = 0;
        global.grav_dir = 0;
    }
}
// ======================================================
// 5. 메뉴 상태 처리
// ======================================================
else {
    var _btn_x = [32, 185, 345, 500];
    var _btn_y = 432;
    var _confirm = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter);
    var _cancel  = keyboard_check_pressed(ord("X")) || keyboard_check_pressed(vk_shift);
    var _ms = global.menu_state;

    // 메인 메뉴
    if (_ms == 0) {
        if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
            global.menu_select = (global.menu_select + 1) % 4;
        }
        if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
            global.menu_select = (global.menu_select + 3) % 4;
        }

        if (instance_exists(obj_player)) {
            obj_player.visible = true;
            obj_player.x = _btn_x[global.menu_select] + 16;
            obj_player.y = _btn_y + 21;
        }

        if (_confirm) {
            if (global.menu_select == 0) {
                // FIGHT 선택
                global.fight_active = true;
                global.fight_stopped = false;
                global.fight_cursor_x = global.fight_center_x - sprite_get_width(spr_fight_bg) / 2;
                global.fight_damage = 0;
                if (instance_exists(obj_player)) obj_player.visible = false;
            }
            else {
                // ACT / ITEM / MERCY 선택
                global.menu_state = global.menu_select;
                global.sub_select = 0;
            }
        }
    }
    // 결과 문장 (턴 종료 메시지)
    else if (_ms == 4) {
        if (instance_exists(obj_player)) obj_player.visible = false;

        if (_confirm) {
            if (global.msg_end) {
                game_end();
            } else {
                start_enemy_turn();
            }
        }
    }
    // ACT / ITEM / MERCY 목록
    else {
        var _count = 0;
        if (_ms == 1) _count = array_length(global.act_names);
        else if (_ms == 2) _count = array_length(global.item_names);
        else if (_ms == 3) _count = array_length(global.mercy_names);

        if (_count > 0) {
            if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
                global.sub_select = (global.sub_select + 1) % _count;
            }
            if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
                global.sub_select = (global.sub_select + _count - 1) % _count;
            }
        }

        if (instance_exists(obj_player)) {
            obj_player.visible = true;
            obj_player.x = global.box_left + 30;
            obj_player.y = global.box_top + 32 + global.sub_select * 36;
        }

        if (_cancel || (_confirm && _count == 0)) {
            global.menu_state = 0;
        }
        else if (_confirm) {
            var _sel = global.sub_select;

            if (_ms == 1) {
                // ACT
                if (_sel == 0) {
                    global.msg = \"SANS - ATK 1 DEF 1\\n* The easiest enemy. Can only deal 1 damage.\";\n                } else {
                    global.talk_count += 1;
                    if (global.talk_count >= 2) {
                        global.msg = \"Sans seems tired.\\n* He might spare you now.\";\n                    } else {
                        global.msg = \"You talked to Sans.\\n* He just keeps grinning.\";\n                    }
                }
            }
            else if (_ms == 2) {
                // ITEM
                var _heal = global.item_heal[_sel];
                var _name = global.item_names[_sel];
                global.hp_current = min(global.hp_max, global.hp_current + _heal);
                global.msg = \"You ate the \" + _name + \".\\n* You recovered \" + string(_heal) + \" HP!\";\n                array_delete(global.item_names, _sel, 1);
                array_delete(global.item_heal, _sel, 1);
            }
            else if (_ms == 3) {
                // MERCY
                if (_sel == 0) {
                    if (global.talk_count >= 2) {
                        global.msg = \"Sans spared you.\\n* The battle is over.\";\n                        global.msg_end = true;
                    } else {
                        global.msg = \"Sans isn't ready to spare you.\";\n                    }
                } else {
                    global.msg = \"You can't escape!\";\n                }
            }

            global.menu_state = 4;
            global.sub_select = 0;
        }
    }
}
