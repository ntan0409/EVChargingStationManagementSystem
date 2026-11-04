// import { useState } from 'react';
import api from './axios';


const BASE_URL = '/Role';

export const create = async (roleName) => {
    try {
        const response = await api.post(`${BASE_URL}/create`,
            { roleName });
        return response.data; // trả về vai trò vừa tạo
    } catch (error) {
        console.error('Error creating role:', error);
        throw error;
    }
}

export const addToUser = async (userId, roleName) => {
    try {
        const response = await api.post(`${BASE_URL}/add-to-user`,
            { userId, roleName });
        return response.data; // trả về thông tin cập nhật của user
    } catch (error) {
        console.error('Error adding role to user:', error);
        throw error;
    }
}

export const getAllRole = async () => {
    try {
        const response = await api.get(`${BASE_URL}/all`);
        return response.data; // trả về danh sách vai trò
    }catch (error) {
        console.error('Error fetching roles:', error);
        throw error;
    }
}