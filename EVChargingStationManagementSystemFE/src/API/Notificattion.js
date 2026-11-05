import React from 'react'
import api from './axios';
const BASE_URL = "/Notification";

export const getNotificattion = async ()=> {
  try {
    const response = await api.get(`${BASE_URL}`);
    console.log('GetNotification Success',response);
    return response;
  } catch (error) {
    console.log('ErrorGetGetNotification',error);
    throw error;
  }
}
export const getNotificattionUnRead = async() =>{
    try {
        const response = await api.get(`${BASE_URL}/unread-count`);
        console.log('GetNotificationUnreadCount Success',response)
        return response
    } catch (error) {
        console.log('ErrorGetNotificationUnreadCount',error);
        throw error;
    }
}
export const getNotificattionMarkRead = async () =>{
    try {
        const response = await api.patch(`${BASE_URL}/mark-all-read`);
        console.log('GetNotificattionMarkRead Success',response)
        return response;
    } catch (error) {
        console.log('ErrorGetNotificattionMarkRead',error);
        throw error;
    }
}

export default {
    getNotificattion,
    getNotificattionUnRead
}
