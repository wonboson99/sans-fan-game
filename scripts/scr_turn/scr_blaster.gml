/// @function spawn_blaster(_sx, _sy, _tx, _ty, _ang)
/// 블래스터 생성 (scr_turn에서도 정의했으므로 이건 백업용)
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
