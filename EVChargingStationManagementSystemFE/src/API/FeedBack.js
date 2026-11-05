import React from 'react'
import api from './axios';

const BASE_URL = "/Feedback";
export const getFeedBack = async () => {
    try {
        const response = await api.get(`${BASE_URL}`)
        console.log('GetFeedback',response);
        return response.data;
    } catch (error) {
        console.log('ErrorGetFeedBack',error)
        throw error;
    }
  
}
export const addFeedBack = async (
    subject,
    stars,
    message
) =>{
    try {
        const response = await api.post(`${BASE_URL}`,{
            subject,
            stars,
            message
        });
        console.log('AddFeedBack',response.data);
        return response.data;
    } catch (error) {
        console.log('ErrorAddFeedBack', error);
        throw error;
    }
}

export default {
    addFeedBack,
    getFeedBack
}
