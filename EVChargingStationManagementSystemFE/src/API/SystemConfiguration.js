import api from "./axios";

const BASE_URL = "/SystemConfiguration";

export const GetList = async () => {
    try {
        const response = await api.get(`${BASE_URL}/GetList`);
        console.log('Danh sách SystemConfiguration:', response.data);
        return response.data;
    } catch (error) {
        console.error('Error GetList SystemConfiguration:', error);
        throw error;
    }
}

// Update một cấu hình theo id
export const Update = async (id, payload) => {
    try {
        const response = await api.put(`${BASE_URL}/Update/${id}`, payload);
        console.log(`SystemConfiguration ${id} updated:`, response.data);
        return response.data;
    } catch (error) {
        console.error('Error Update SystemConfiguration:', error);
        throw error;
    }
}

export const GetByConfigName = async (configName) => {
    try {
        const response = await api.get(`${BASE_URL}/${configName}`);
        return response.data;
    } catch (error) {
        console.error('Error GetByConfigName SystemConfiguration:', error);
        throw error;
    }
}

export const GetVAT = async () => {
    try {
        const response = await api.get(`${BASE_URL}/vat`);
        return response.data;
    } catch (error) {
        console.error('Error GetVAT SystemConfiguration:', error);
        throw error;
    }
}

export const GetPrice = async () => {
    try {
        const response = await api.get(`${BASE_URL}/price-per-kwh`);
        return response.data;
    } catch (error) {
        console.error('Error GetPrice SystemConfiguration:', error);
        throw error;
    }
}
