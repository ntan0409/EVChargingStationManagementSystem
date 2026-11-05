import api from "./axios";

const BASE_URL = "/ChargingStation";

export const getChargingStation = async () => {
  try {
    const response = await api.get(`${BASE_URL}`);
    console.log('Danh sách ChargingStation:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error getChargingStation:', error);
    throw error;
  }
};

export const addChargingStation = async (
  stationName,
  location,
  province,
  latitude,
  longitude,
  operatorId,
  status
  
) => {
  try {
    const response = await api.post(`${BASE_URL}`, {
      stationName,
      location,
      province,
      latitude,
      longitude,
      operatorId,
      status,
    });
    console.log('addStation - response:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error addChargingStation:', error);
    throw error;
  }
};

export const updateChargingStation = async (id, stationData) => {
  try {
    const response = await api.put(`${BASE_URL}`, stationData, {
      params: { stationId: id } 
    });
    console.log('updateStation - response:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error updateChargingStation:', error);
    throw error;
  }
};


export const deleteChargingStation = async (id) => {
  try {
    const response = await api.delete(`${BASE_URL}`, {
      params: { stationId: id } 
    });
    console.log('deleteStation - response:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error deleteChargingStation:', error);
    throw error;
  }
};



export const getChargingStationId = async (id) => {
  try {
    const response = await api.get(`${BASE_URL}/${id}`);
    console.log("Chi tiết station:", response.data);
    return response.data.data; //  Trả về đúng object station
  } catch (error) {
    console.error("Error getChargingStationId:", error);
    throw error;
  }
};

export const updateChargingStationStatus = async (id, status) => {
  try {
    const response = await api.patch(`${BASE_URL}/status`, null,{
      params:{ stationId: id, status },
    });
    console.log('updateStatus - response:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error updateChargingStationStatus:', error);
    throw error;
  }
};
export const getStaffWorkingStation = async() =>{
  try {
    const response = await api.get(`${BASE_URL}/staff`);
    console.log('GetStaffWorkingStationSuccess',response)
    return response.data
  } catch (error) {
    console.log('ErrorGetStaffWorkingStation',error);
    throw error
  }
}

export default {
  getChargingStation,
  addChargingStation,
  deleteChargingStation,
  updateChargingStation,
  getChargingStationId,
  updateChargingStationStatus,
  getStaffWorkingStation
};
