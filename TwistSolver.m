clear all; close all; clc

% 这里假设目标是装甲片在相机坐标系下xy分量为0，若需要枪管则多乘一个变换矩阵
syms theta_yaw_current theta_pitch_current real % 当前电机角度，设居中时为零度
assume(theta_yaw_current<pi/2)
assume(theta_yaw_current>-pi/2)
assume(theta_pitch_current<pi/2)
assume(theta_pitch_current>-pi/2)
syms theta_yaw_destiny theta_pitch_destiny % 目标电机角度，设居中时为零度
syms x_target y_target z_target real % 相机坐标系下装甲板位置
assume(z_target>0)

x_s_camera=0; y_s_camera=-0.5; z_s_camera=0.25; % 世界坐标系下相机位置
x_s_yaw=0;y_s_yaw=0;z_s_yaw=0; % 世界坐标系下yaw电机位置
x_s_pitch=-0.25;y_s_pitch=0;z_s_pitch=0.25; % 世界坐标系下pitch电机位置

T_s_yaw_origin=[eye(3), [x_s_yaw; y_s_yaw; z_s_yaw]; 0, 0, 0, 1]; % 零度时世界坐标系到yaw电机
T_s_pitch_origin=[[0, 0, -1; -1, 0, 0; 0, 1, 0], [x_s_pitch; y_s_pitch; z_s_pitch]; 0, 0, 0, 1]; % 零度时世界坐标系到pitch电机
T_s_camera_origin=[[1, 0, 0; 0, 0, -1; 0, 1, 0], [x_s_camera; y_s_camera; z_s_camera]; 0, 0, 0, 1]; % 零度时世界坐标系到相机

S_yaw_yaw=[0; 0; 1; 0; 0; 0]; % yaw坐标系下yaw电机twist
S_yaw_s=Adjoint(T_s_yaw_origin)*S_yaw_yaw; % 世界坐标系下yaw电机twist
S_pitch_pitch=[0; 0; 1; 0; 0; 0]; % pitch坐标系下pitch电机twist
S_pitch_s=Adjoint(T_s_pitch_origin)*S_pitch_pitch; % 世界坐标系下pitch电机twist

CrossMatrix_yaw_s=VecTose3(S_yaw_s);
CrossMatrix_pitch_s=VecTose3(S_pitch_s);

T_s_yaw_current=expm(CrossMatrix_yaw_s*theta_yaw_current)*T_s_yaw_origin; % 当前世界坐标系到yaw电机
T_s_pitch_current=expm(CrossMatrix_yaw_s*theta_yaw_current)*expm(CrossMatrix_pitch_s*theta_pitch_current)*T_s_pitch_origin; % 当前世界坐标系到pitch电机
T_s_camera_current=expm(CrossMatrix_yaw_s*theta_yaw_current)*expm(CrossMatrix_pitch_s*theta_pitch_current)*T_s_camera_origin; % 当前世界坐标系到相机
T_camera_target_current=[eye(3), [x_target; y_target; z_target]; 0, 0, 0, 1]; % 当前相机到装甲片
T_s_target_current=T_s_camera_current*T_camera_target_current;

T_s_yaw_current=expm(CrossMatrix_yaw_s*theta_yaw_destiny)*T_s_yaw_origin; % 旋转后世界坐标系到yaw电机
T_s_pitch_current=expm(CrossMatrix_yaw_s*theta_yaw_destiny)*expm(CrossMatrix_pitch_s*theta_pitch_destiny)*T_s_pitch_origin; % 旋转后世界坐标系到pitch电机
T_s_camera_destiny=expm(CrossMatrix_yaw_s*theta_yaw_destiny)*expm(CrossMatrix_pitch_s*theta_pitch_destiny)*T_s_camera_origin; % 旋转后世界坐标系到相机
T_camera_target_destiny=T_s_camera_destiny\T_s_target_current; % 旋转后的相机坐标系到装甲片坐标系

theta_destiny=solve(T_camera_target_destiny(1:2, 4)==[0; 0], [theta_pitch_destiny, theta_yaw_destiny], 'ReturnConditions', true); % 目标转角
theta_destiny=subs([theta_destiny.theta_pitch_destiny, theta_destiny.theta_yaw_destiny], theta_destiny.parameters, [0, 0]);

function se3mat = VecTose3(V)
se3mat = [VecToso3(V(1: 3)), V(4: 6); 0, 0, 0, 0];
end

function AdT = Adjoint(T)
[R, p] = TransToRp(T);
AdT = [R, zeros(3); VecToso3(p) * R, R];
end

function [R, p] = TransToRp(T)
R = T(1: 3, 1: 3);
p = T(1: 3, 4);
end

function so3mat = VecToso3(omg)
so3mat = [0, -omg(3), omg(2); omg(3), 0, -omg(1); -omg(2), omg(1), 0];
end