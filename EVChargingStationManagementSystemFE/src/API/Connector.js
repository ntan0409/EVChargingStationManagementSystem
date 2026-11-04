import api from "./axios";

const BASE_URL = "/Connector";

export const GetConnector = async () => {
    try {
        const response = await api.get(`${BASE_URL}`);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi lấy danh sách connector:', error);
        throw error;
    }
}

export const PostConnector = async (
    connectorName,
    getChargingPostId) => {
    try {
        const response = await api.post(`${BASE_URL}`, {
            connectorName,
            getChargingPostId
        });
        return response.data;
    } catch (error) {
        console.error('Lỗi khi thêm mới connector:', error);
        throw error;
    }
}

export const PutConnector = async (
    connectorId,
    connectorName,
    chargingPostId
) => {
    try {
        const response = await api.put(`${BASE_URL}`, {
            connectorId,
            connectorName,
            chargingPostId
        });
        return response.data;
    } catch (error) {
        console.error('Lỗi khi cập nhật connector:', error);
        throw error;
    }
}

export const DeleteConnector = async (connectorId) => {
    try {
        const response = await api.delete(`${BASE_URL}/${connectorId}`);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi xóa connector:', error);
        throw error;
    }
}

export const GetConnectorId = async (connectorId) => {
    try {
        const response = await api.get(`${BASE_URL}/${connectorId}`, { connectorId });
        return response.data;
    } catch (error) {
        console.error(`Lỗi khi lấy connector với id ${connectorId}:`, error);
        throw error;
    }
}

export const PatchConnectorStatus = async (connectorId, status) => {
    try {
        const response = await api.patch(`${BASE_URL}/status`, { connectorId, status });
        return response.data;
    } catch (error) {
        console.error('Lỗi khi cập nhật trạng thái connector:', error);
        throw error;
    }
}

export const PatchConnectorToggle = async (toggle, connectorId) => {
    try {
        // gửi dữ liệu qua query params chứ không phải body
        const response = await api.patch(`${BASE_URL}/connector-toggle`, null, {
            params: { toggle, connectorId },
        });
        return response.data;
    } catch (error) {
        console.error("Lỗi khi cập nhật trạng thái connector:", error);
        throw error;
    }
};
