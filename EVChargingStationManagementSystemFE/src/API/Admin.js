// import React from 'react';
import api from "./axios";



const BASE_URL = "/VehicleModel";




export const getVehicleModels = async () => {
  try {
    const response = await api.get(`${BASE_URL}`);
    
    return response.data;
  } catch (error) {
    console.error('Lỗi khi lấy danh sách vehicleModel:', error);
    throw error;
  }
};

export const addVehicalModel = async (
    modelName,
    modelYear,
    vehicleType, // ở đây phải là số: 0, 1, 2
    batteryCapacityKWh,
    recommendedChargingPowerKW,
    imageUrl
) => {
    try {
        const response = await api.post(`${BASE_URL}`, {
            modelName,  
            modelYear: Number(modelYear),
            vehicleType: Number(vehicleType), // bắt buộc số
            batteryCapacityKWh: Number(batteryCapacityKWh),
            recommendedChargingPowerKW: Number(recommendedChargingPowerKW),
            imageUrl
        });

        
        return response.data;
    } catch (error) {
        console.error('Lỗi khi thêm VehicleModel:', error.response?.data || error);
        throw error;
    }
};



//updateVehicle 

export const updateVehicle = async (modelData) => {
  try {
    const response = await api.put(`${BASE_URL}`, modelData); {
      
      return response.data;
    }
  } catch (error) {
    console.error('lỗi khi cập nhật VehicleModel:', error);
    throw error;
  }
};

//delete
export const deleteVehicle = async (id) => {
  try {
    const response = await api.delete(`/VehicleModel`, {
      params: { vehicleModelId: id } // gửi id dưới dạng query param
    });
    
    return response.data;
  } catch (error) {
    console.error('lỗi khi xóa VehicleModel', error);
    throw error;
  }
};


//lấy 1 xe theo ID
export const getVehicleById = async (id) => {
  try {
    const response = await api.get(`${BASE_URL}/${id}`);
    
    return response.data;
  } catch (error) {
    console.error('lỗi khi lấy chi tiết VehicleModel:', error);
    throw error;
  }
};

// cập nhật dựa vào trạng thái 
export const updateVehicleStatus = async (id, status) => {
  try {
    const response = await api.patch(`${BASE_URL}/status`, {
      id,
      status,
    });
    
    return response.data;
  } catch (error) {
    console.error('lỗi khi cập nhật status VehicleModel:', error);
    throw error;
  }
}


export default {
  getVehicleModels,
  addVehicalModel,
  updateVehicle,
  deleteVehicle,
  getVehicleById,
  updateVehicleStatus,
};


