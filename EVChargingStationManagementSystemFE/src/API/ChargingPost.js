import api from "./axios";

const BASE_URL = "/ChargingPost";

// 🔹 Get all posts (có thể kèm stationId)
export const getAllChargingPost = async (stationId = null) => {
  try {
    const response = await api.get("/ChargingPost");
    let data = response.data.data || [];

    // Nếu có stationId thì lọc ngay tại FE
    if (stationId) {
      data = data.filter((p) => p.stationId === stationId);
    }

    console.log("Danh sách ChargingPost:", data);
    return data;
  } catch (error) {
    console.error("Error getAllChargingPost:", error);
    throw error;
  }
};

// 🔹 Add post
export const addChargingPost = async (data) => {
  try {
    const response = await api.post(`${BASE_URL}`, data);
    console.log("addPost - response:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error addChargingPost:", error);
    throw error;
  }
};

// 🔹 Update post info
export const updateChargingPost = async (postId, postData) => {
  try {
    const response = await api.put(`${BASE_URL}`, postData, {
      params: { postId },
    });
    console.log("updatePost - response:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error updateChargingPost:", error);
    throw error;
  }
};

// 🔹 Delete post
export const deleteChargingPost = async (postId) => {
  try {
    const response = await api.delete(`${BASE_URL}`, {
      params: { postId },
    });
    console.log("deletePost - response:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error deleteChargingPost:", error);
    throw error;
  }
};

// 🔹 Get by ID
export const getChargingPostId = async (id) => {
  try {
    const response = await api.get(`${BASE_URL}/${id}`);
    console.log("Chi tiết Post:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error getChargingPostId:", error);
    throw error;
  }
};

// 🔹 Update status
export const updateChargingPostStatus = async (postId, status) => {
  try {
    const response = await api.patch(`${BASE_URL}/status`, null, {
      params: { postId, status },
    });
    console.log("updateStatus - response:", response.data);
    return response.data;
  } catch (error) {
    console.error("Error updateChargingPostStatus:", error);
    throw error;
  }
};

export default {
  getAllChargingPost,
  addChargingPost,
  updateChargingPost,
  deleteChargingPost,
  getChargingPostId,
  updateChargingPostStatus,
};
