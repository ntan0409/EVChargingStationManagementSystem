import api from "./axios";

const BASE_URL = "/VehicleModel";

export const GetVehicleModel = async () => {
    try {
        const response = await api.get(`${BASE_URL}`);
        // console.log('Danh Sách VehicleModel:', response.data);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi lấy danh sách vehicleModel:', error);
        throw error;
    }
}

export const PostVehicleModel = async (
    modelName,
    modelYear,
    vehicleType,
    batteryCapacityKWh,
    recommendedChargingPowerKW,
    imageUrl,
    status
) => {
    try {
        const response = await api.post(`${BASE_URL}`, {
            modelName,
            modelYear,
            vehicleType,
            batteryCapacityKWh,
            recommendedChargingPowerKW,
            imageUrl,
            status
        });
        return response.data;
    } catch (error) {
        console.error('Lỗi khi thêm mới vehicleModel:', error);
        throw error;
    }
}

export const UpdateVehicleModel = async (vehicleModelId, payload) => {
    try {
        const url = `${BASE_URL}?vehicleModelId=${encodeURIComponent(vehicleModelId)}`;
        const response = await api.put(url, payload);
        return response.data;
    } catch (error) {
        console.error(`Lỗi khi cập nhật vehicleModel ${vehicleModelId}:`, error);
        throw error;
    }
}

export const GetVehicleModelById = async (vehicleModelId) => {
    try {
        const response = await api.get(`${BASE_URL}/${vehicleModelId}`);
        return response.data;
    } catch (error) {
        console.error(`Lỗi khi lấy vehicleModel ${vehicleModelId}:`, error);
        throw error;
    }
}

// export const DeleteVehicleModel = async (vehicleModelId) => {
//     try {
//         const response = await api.delete(`${BASE_URL}/${vehicleModelId}`);
//         return response.data;
//     } catch (error) {
//         console.error(`Lỗi khi xoá vehicleModel ${vehicleModelId}:`, error);
//         throw error;
//     }
// }

export const DeleteVehicleModel = async (vehicleModelId) => {
    try {
        console.log("Đang gửi yêu cầu xóa:", `${BASE_URL}?vehicleModelId=${vehicleModelId}`);
        const response = await api.delete(`${BASE_URL}?vehicleModelId=${vehicleModelId}`);
        console.log("Kết quả:", response.data);
        return response.data;
    } catch (error) {
        console.error("Chi tiết lỗi xoá vehicleModel:", error.response?.data || error.message);
        throw error;
    }
};


// export const VehicleStatus = async (vehicleModelId) => {
//     try {
//         const response = await api.get(`${BASE_URL}/VehicleStatus`, { vehicleModelId });
//         return response.data;
//     } catch (error) {
//         console.error('Lỗi khi lấy trạng thái vehicleModel:', error);
//         throw error;
//     }
// }

export const VehicleStatus = async (vehicleModelId) => {
    try {
        const response = await api.get(`${BASE_URL}/VehicleStatus`, {
            params: { vehicleModelId },
        });
        return response.data;
    } catch (error) {
        console.error("Lỗi khi lấy trạng thái vehicleModel:", error);
        throw error;
    }
}

export const UpdateVehicleModelStatus = async (vehicleModelId, status) => {
    try {
        const response = await api.patch(`${BASE_URL}/status`, null, {
            params: {
                vehicleModelId: vehicleModelId,
                status: status
            }
        });
        return response.data;
    } catch (error) {
        console.error(`Lỗi khi cập nhật trạng thái vehicleModel ${vehicleModelId}:`, error);
        throw error;
    }
}