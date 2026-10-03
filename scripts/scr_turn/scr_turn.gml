/// @function start_enemy_turn()
/// 적 턴 시작 - 플레이어를 중앙에 배치하고 공격 타이머 초기화
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

    obj_battle_manager.alarm[0] = 250;
}

/// @function change_gravity(_nd)
/// 중력 방향 변경 및 내리찍기
function change_gravity(_nd) {
    var _same = (_nd == global.grav_dir);
    global.grav_dir = _nd;
    global.last_dir_t = global.attack_timer;

    if (instance_exists(obj_player)) {
        with (obj_player) {
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

/// @function spawn_blaster(_sx, _sy, _tx, _ty, _ang)
/// 블래스터 생성 함수
function spawn_blaster(_sx, _sy, _tx, _ty, _ang) {
    var _b = instance_create_layer(_sx, _sy, "Instances", obj_blaster);
    _b.start_x = _sx;
    _b.start_y = _sy;
    _b.target_x = _tx;
    _b.target_y = _ty;
    _b.start_angle = _ang;
    _b.target_angle = _ang;
    _b.image_angle = _ang;
    return _b;
}

/// 턴별 패턴 함수들

/// @function pattern_turn1()
/// 턴 1: 기본 뼈 벽 - 좌우에서 나오지만 가운데 안전 구간 유지
function pattern_turn1() {
    var _t = global.attack_timer;
    
    // 30프레임부터 시작해서 60프레임까지 뼈 생성
    if (_t >= 30 && _t < 150 && _t % 35 == 0) {
        var _bone_left = instance_create_layer(global.box_left - 30, 0, "Instances", obj_bonefield);
        _bone_left.dir = 2; // 왼쪽에서
        
        var _bone_right = instance_create_layer(global.box_right + 30, 0, "Instances", obj_bonefield);
        _bone_right.dir = 3; // 오른쪽에서
    }
}

/// @function pattern_turn2()
/// 턴 2: 좌우 번갈아 뼈 - 한 번에 한쪽만 공격
function pattern_turn2() {
    var _t = global.attack_timer;
    global.soul_mode = 0;
    
    // 왼쪽 → 오른쪽 → 왼쪽 번갈아
    if (_t == 40 || _t == 110) {
        var _bone = instance_create_layer(global.box_left - 30, 0, "Instances", obj_bonefield);
        _bone.dir = 2;
    }
    
    if (_t == 75 || _t == 145) {
        var _bone = instance_create_layer(global.box_right + 30, 0, "Instances", obj_bonefield);
        _bone.dir = 3;
    }
}

/// @function pattern_turn3()
/// 턴 3: 블래스터 + 뼈 조합 - 복합 패턴
function pattern_turn3() {
    var _t = global.attack_timer;
    global.soul_mode = 0;
    
    // 뼈 한쪽에서만
    if (_t == 30 || _t == 90) {
        var _bone = instance_create_layer(global.box_left - 30, 0, "Instances", obj_bonefield);
        _bone.dir = 2;
    }
    
    // 중앙에서 블래스터 1개
    if (_t == 60) {
        var _mid = (global.box_left + global.box_right) / 2;
        var _bl = spawn_blaster(_mid, global.box_top - 30, _mid, global.box_bottom + 30, 90);
        _bl.fire_time = 50;
    }
    
    if (_t == 130) {
        var _mid = (global.box_left + global.box_right) / 2;
        var _bl = spawn_blaster(_mid, global.box_top - 30, _mid, global.box_bottom + 30, 90);
        _bl.fire_time = 50;
    }
}

/// @function pattern_turn4()
/// 턴 4: 파랑 모드 - 중력 반전 + 안전 경로 유지
function pattern_turn4() {
    var _t = global.attack_timer;
    global.soul_mode = 1;
    
    // 처음 중력 반전
    if (_t == 25) {
        with (obj_bonefield) instance_destroy();
        change_gravity(irandom(3));
        
        var _bf = instance_create_layer(0, 0, "Instances", obj_bonefield);
        _bf.dir = global.grav_dir;
    }
    
    // 두 번째 중력 반전 (다른 방향)
    if (_t == 100) {
        with (obj_bonefield) instance_destroy();
        var _new_dir = irandom(3);
        while (_new_dir == global.grav_dir) _new_dir = irandom(3);
        change_gravity(_new_dir);
        
        var _bf = instance_create_layer(0, 0, "Instances", obj_bonefield);
        _bf.dir = global.grav_dir;
    }
    
    // 블래스터 1개
    if (_t == 60 && instance_exists(obj_player)) {
        var _p = obj_player;
        var _bl = spawn_blaster(_p.x, global.box_top - 30, _p.x, global.box_bottom + 30, 90);
        _bl.fire_time = 40;
    }
}

/// @function update_attack_pattern()
/// 현재 턴에 맞는 패턴 실행
function update_attack_pattern() {
    var _turn = global.turn;
    
    if (_turn == 1) {
        pattern_turn1();
    }
    else if (_turn == 2) {
        pattern_turn2();
    }
    else if (_turn == 3) {
        pattern_turn3();
    }
    else if (_turn == 4) {
        pattern_turn4();
    }
    else {
        // 5턴 이후: 기본 패턴 반복
        if (global.attack_timer % 40 == 0) {
            var _b = instance_create_layer(global.box_right + 30, 0, "Instances", obj_bonefield);
            _b.dir = 3;
        }
    }
}
