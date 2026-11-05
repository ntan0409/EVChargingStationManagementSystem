import React from 'react'
import api from './axios'
const BASE_URL="/EVDriver";

export const getEVDriver= async ()=> {
    try {
        const response = await api.get(`${BASE_URL}/all`);
        console.log('Danh sach driver',response);
        return response;
    } catch (error) {
        console.log('Error GetEVDriver',error);
        throw error;
    }
}

export const updateEVDriver = async (
    driverId,
    name,
    phoneNumber,
    address,
    profilePictureUrl,
    vehicleModelIds,
)=>{
    try {
        const response = await api.put(`${BASE_URL}/update`,{
            driverId,
            name,
            phoneNumber,
            address,
            profilePictureUrl,
            vehicleModelIds,
        }); 
        console.log('updateEvdriver',response.data);
        return response;
    } catch (error) {
        console.log('errorUpdate',error);
        throw error;
    }
}
export const getEVDriverId = async (driverId) => {
  try {
    const response = await api.get(`${BASE_URL}/${driverId}`);
    console.log("Thông tin EVDriver:", response.data);
    return response.data;
  } catch (error) {
    console.log("Error GetEVDriver", error);
    throw error;
  }
};

export const getEVDriverProfile = async ()=>{
    try {
        const response = await api.get(`${BASE_URL}/profile`)
        console.log('GetProfile',response.data);
        return response.data;
    } catch (error) {
        console.log('Error GetProfile',error)
        throw error
    }
}
export const deleteEVDriverVehicalid = async (vehicleModelId) =>{
    try {
        const response = await api.delete(`${BASE_URL}/vehicle/${vehicleModelId}`,);
        console.log('DeleteVehicleInProfile success',response.data)
        return response.data;
    } catch (error) {
        console.log('Xoa That Bai Xe Trong Profile',error);
        throw error;
    }
}


export default {
    getEVDriver,
    updateEVDriver,
    getEVDriverId,
    deleteEVDriverVehicalid
}