import api from './axios';

const BASE_URL = "/Booking";

// Lấy danh sách tất cả Booking
export const getBooking = async () => {
  try {
    const response = await api.get(`${BASE_URL}`);
    console.log('Danh sách Booking:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error BookingGET', error);
    throw error;
  }
};

// Thêm mới Booking
export const addBooking = async (stationId, vehicleId, startTime, currentBattery, targetBattery) => {
  try {
    const response = await api.post(`${BASE_URL}`, {
      stationId,
      vehicleId,
      startTime,
      currentBattery,
      targetBattery
    });
    console.log('addBooking-response', response.data);
    return response.data;
  } catch (error) {
    console.error('ErrorAddBooking', error);
    throw error;
  }
};

// Lấy chi tiết Booking theo ID
export const getBookingId = async (id) => {
  try {
    const response = await api.get(`${BASE_URL}/${id}`);
    console.log('DetailBooking', response.data);
    return response.data;
  } catch (error) {
    console.error('Error BookingID', error);
    throw error;
  }
};

// Check-in Booking // check
export const BookCheckin = async (checkInCode) => {
  try {
    const response = await api.patch(`${BASE_URL}/checkin`, { checkInCode });
    console.log('checkInCode', response.data);
    return response.data;
  } catch (error) {
    console.error('ErrorCheckin', error);
    throw error;
  }
};

// Hoàn tất Booking
export const BookComplete = async (bookingId, batteryCapacity) => {
  try {
    const response = await api.patch(`${BASE_URL}/${bookingId}/complete`, null, {
      params: { batteryCapacity }
    });
    console.log('CompleteBooking', response.data);
    return response.data;
  } catch (error) {
    console.error('ErrorComplete', error);
    throw error;
  }
};

// Hủy Booking
export const BookCancel = async (bookingId) => {
  try {
    const response = await api.patch(`${BASE_URL}/${bookingId}/cancel`);
    console.log('CancelBooking', response.data);
    return response.data;
  } catch (error) {
    console.error('ErrorCancel', error);
    throw error;
  }
};

// Tự động hủy
export const AutoCancel = async (bookingId) => {
  try {
    const response = await api.patch(`${BASE_URL}/${bookingId}/cancel`);
    console.log('CancelBooking', response.data);
    return response.data;
  } catch (error) {
    console.error('ErrorCancelBooking', error);
    throw error;
  }
};

// Tự động gán lại
export const AutoReassign = async () => {
  try {
    const response = await api.post(`${BASE_URL}/autoreassign`);
    console.log('AutoReassign', response.data);
    return response.data;
  } catch (error) {
    console.error('ErrorAutoReassign', error);
    throw error;
  }
};

// Tự động khóa
export const AutoLock = async () => {
  try {
    const response = await api.post(`${BASE_URL}/autolock`);
    console.log('AutoLock', response.data);
    return response.data;
  } catch (error) {
    console.error('ErrorAutoLock', error);
    throw error;
  }
};
export const MyBooking = async () => {
  try {
    const response = await api.get(`${BASE_URL}/my-bookings`);
    console.log('MyBooking', response.data);
    return response.data;
  } catch (error) {
    console.log('ErrorToGetMyBooking', error);
    throw error;
  }
}
export const getStationBooking = async () =>{
  try {
    const response = await api.get(`${BASE_URL}/station-bookings`);
    console.log ('GetStationBooking',response);
    return response.data
  } catch (error) {
    console.log('ErrorGetStationBooking',error)
    throw error;
  }
}

export default {
  getBooking,
  addBooking,
  getBookingId,
  BookCheckin,
  BookComplete,
  BookCancel,
  AutoCancel,
  AutoReassign,
  AutoLock,
  MyBooking
};
