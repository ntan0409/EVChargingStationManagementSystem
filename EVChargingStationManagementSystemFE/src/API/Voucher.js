import api from "./axios";

const BASE_URL = "/Voucher";

//getallvoucher(user)
export const GetVoucher = async () => {
    try {
        const response = await api.get(`${BASE_URL}`);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi lấy danh sách voucher:', error);
        throw error;
    }
}

export const GetAdminVouchers = async () => {
    try {
        const response = await api.get(`${BASE_URL}/admin`);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi lấy danh sách voucher cho admin:', error);
        throw error;
    }
}

//tạo voucher
export const PostVoucher = async (data) => {
    try {
        const response = await api.post(`${BASE_URL}`, data);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi thêm mới voucher:', error);
        throw error;
    }
}

//cập nhật voucher
export const UpdateVoucher = async (voucherId, payload) => {
    try {
        const response = await api.put(`${BASE_URL}/${voucherId}`, payload);
        return response.data;
    } catch (error) {
        console.error(`Lỗi khi cập nhật voucher ${voucherId}:`, error);
        throw error;
    }
}

//xóa voucher
export const DeleteVoucher = async (voucherId) => {
    try {
        const response = await api.delete(`${BASE_URL}/${voucherId}`);
        return response.data;
    } catch (error) {
        console.error(`Lỗi khi xóa voucher ${voucherId}:`, error);
        throw error;
    }
}

//đổi voucher
export const RedeemVoucher = async (voucherId) => {
    try {
        const response = await api.post(`${BASE_URL}/redeem/${voucherId}`);
        return response.data;
    } catch (error) {
        console.error(`Lỗi khi đổi voucher ${voucherId}:`, error);
        throw error;
    }
}

//sử dụng voucher(user)
export const useVoucher = async (userVoucherId, sessionId) => {
    try {
        const response = await api.post(`${BASE_URL}/use/${userVoucherId}`, { sessionId });
        return response.data;
    } catch (error) {
        console.error(`Lỗi khi sử dụng voucher ${userVoucherId}:`, error);
        throw error;
    }
}

//voucher của user
export const GetUserVouchers = async () => {
    try {
        const response = await api.get(`${BASE_URL}/my`);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi lấy danh sách voucher của user:', error);
        throw error;
    }
}


