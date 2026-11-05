import api from "./axios";

const BASE_URL = "/Payment";

export const PostPayment = async (sessionId) => {
    try {
        const response = await api.post(`${BASE_URL}?sessionId=${sessionId}`);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi tạo payment:', error);
        throw error;
    }
};


export const PostPaymentOffline = async (sessionId) => {
    try {
        const response = await api.post(`${BASE_URL}/offline?sessionId=${sessionId}`);
        return response.data;

    } catch (error) {
        console.error('Lỗi khi tạo payment offline:', error);
        throw error;
    }
}

export const PatchPaymentOfflineStatus = async (paymentId) => {
    try {
        const response = await api.patch(`${BASE_URL}/offline-status/?paymentId=${paymentId}`);
        return response.data;
    } catch (error) {
        console.error('Lỗi khi cập nhật trạng thái payment offline:', error);
        throw error;
    }
}
export const getPaymentThatHaveSend = async () =>{
    try {
        const response = await api.get(`${BASE_URL}`);
        console.log('GetPaymentThatHaveSendSuccess',response);
        return response.data;
    } catch (error) {
        console.log('ErrorGetPayMentThatHaveSend',error);
        throw error;
    }
}