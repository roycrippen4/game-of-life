const std = @import("std");

const raylib = @import("raylib");
const Color = raylib.Color;

pub const fg: Color = .gray;
pub const bg: Color = .black;
pub const accent: Color = .yellow;

pub const button = struct {
    pub const fg: Color = .black;
    pub const bg: Color = .gray;
    pub const border: Color = .black;
};
