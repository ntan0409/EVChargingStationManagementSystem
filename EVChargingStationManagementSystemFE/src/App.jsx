import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
// import Layout from "./pages/Layout";

import Layout from "./components/pages/Layout";
import Home from "./components/pages/Home";
import About from "./components/pages/About";
import Contact from "./components/pages/Contact";
import Login from "./components/pages/Login";
import Profile from "./components/profile/Profile";

import Logout from "./components/pages/Logout";
import PrivateRoute from "./components/pages/PrivateRoute";
import Order from "./components/profile/Order"
import Car from "./components/profile/Car"

import Signup from "./components/pages/Signup";
import Forgotpassword from "./components/pages/Forgotpassword";
import OrderChargingST from "./components/ordercharging/OrderChargingST";
import ChargingPost from "./components/ordercharging/ChargingPost"

// Admin imports
import AdminLayout from "./components/pages/admin/AdminLayout";
import AdminDashboard from "./components/pages/admin/AdminDashboard";
import AdminStations from "./components/pages/admin/Stations";
import AdminStaff from "./components/pages/admin/Staff";
import AdminVehicles from "./components/pages/admin/AdminVehicles";
import AdminVouchers from "./components/pages/admin/AdminVouchers";
import AdminSettings from "./components/pages/admin/AdminSettings";
import AdminPrivateRoute from "./components/pages/admin/AdminPrivateRoute";
import PaymentPage from "./components/Payment/PaymentPage";
import Pay from "./components/Payment/Pay";
import ProfilePage from "./components/profile/ProfilePage";
import ReportPage from "./components/profile/ReportPage";
import RatingPage from "./components/profile/RatingPage";
import AdminStationPanel from "./components/ordercharging/AdminStationPannel";
import IOTChargingSystem from "./components/IOTChargingSystem/IOTChargingSystem.jsx"
import Booking from "./components/ordercharging/Booking.jsx";
import StaffLayout from "./components/pages/staff/StaffLayout.jsx";
import StaffPrivateRoute from "./components/pages/staff/StaffPrivateRoute.jsx";
import AdminStationDetail from "./components/pages/admin/AdminStationDetail.jsx";
import AdminConnector from "./components/pages/admin/AdminConnector.jsx";
import StationList from "./RealDemo/StationList.jsx";
import ChargingPostList from "./RealDemo/ChargingPostList.jsx";
import ConnectorList from "./RealDemo/ConnectorList.jsx";
import Session from "./RealDemo/Session.jsx";
import PaymentOptionPage from "./RealDemo/PaymentOptionPage.jsx";
import Success from "./PaymentStatus/Success.jsx";
import Fail from "./PaymentStatus/Fail.jsx";
import Error from "./PaymentStatus/Error.jsx";
import Invalid from "./PaymentStatus/Invalid.jsx";
import AdminCheckLogin from "./components/pages/admin/Adminchecklogin.jsx"
import BookingOrder from "./components/ordercharging/BookingOrder.jsx"
import StaffBookingOrder from "./components/pages/staff/StaffBookingOrder.jsx";
import NotificationBubble from "./components/notification/NotificationBubble.jsx";
import { NotificationProvider } from "./components/notification/NotificationContext.jsx";



// import NoPage from "./pages/NoPage";
// import ResetPassword from "./components/pages/ResetPassword";
import ResetPassword from "./components/pages/ResetPassword";
import ConfirmEmail from "./components/pages/ConfirmEmail";
import SystemConfigEditor from "./components/pages/admin/SystemConfiguration";
import StaffStation from "./components/pages/staff/StaffStation.jsx";
import ConfirmPaymentOffline from "./components/pages/staff/ConfirmPaymentOffline.jsx";
import StaffStationDetail from "./components/pages/staff/StaffStationDetail.jsx";
import StaffConnector from "./components/pages/staff/StaffConnector.jsx";
import AdminStationMap from "./components/pages/admin/AdminMapStation.jsx"
import AdminSession from "./components/pages/admin/AdminSession.jsx";
import AdminMapStation from "./components/pages/admin/AdminMapStation.jsx";
import RoutingMachine from "./components/ordercharging/RouteMachine.jsx"
import RevenueStatistics from "./components/pages/admin/RevenueStatistics.jsx";
import TransactionHistory from "./components/pages/admin/TransactionHistory.jsx";
import StaffReport from "./components/pages/staff/StaffReport.jsx";
import AdminReportContainer from "./components/pages/admin/AdminReportContainer.jsx";
import UserReport from "./components/profile/UserReport.jsx"
import AdminFeedbackPage from "./components/pages/admin/AdminFeedBackContainer.jsx";
import AdminUser from "./components/pages/admin/Users.jsx"
import PaymentHistory from "./components/profile/PaymentHistory.jsx";



export default function App() {

  return (

    <NotificationProvider>
      <BrowserRouter>
        <ToastContainer
          position="top-right"
          autoClose={3000}
          hideProgressBar={false}
          newestOnTop={false}
          closeOnClick
          rtl={false}
          pauseOnFocusLoss
          draggable
          pauseOnHover
          theme="light"
        />
        <Routes>

          <Route path="/" element={<Layout />}>
            <Route index element={<AdminCheckLogin><Home /></AdminCheckLogin>} />
            {/* LOGIN */}
            <Route path="about" element={<About />} />
            <Route path="contact" element={<Contact />} />
            <Route path="login" element={<Login />} />
            <Route path="sign-up" element={<Signup />} />
            <Route path="forgot-password" element={<Forgotpassword />} />

            {/* // */}
            {/* Profile */}
            <Route path="profile-page" element={<ProfilePage />} />
            <Route path="profile" element={<PrivateRoute><Profile /></PrivateRoute>} />
            <Route path="Logout" element={<Logout />} />
            <Route path="orders" element={<Order />} />
            <Route path="car" element={<Car />} />
            <Route path="report-page" element={<ReportPage />} />
            <Route path="rating-page" element={<RatingPage />} />
            <Route path="user-report" element={<UserReport />} />
            <Route path="payment-history" element={<PaymentHistory />} />

            {/* // */}
            {/* Trạm Sạc */}
            <Route path="order-charging" element={<OrderChargingST />} />
            <Route path="charging-post" element={<ChargingPost />} />
            <Route path="admin-pannel" element={<AdminStationPanel />} />
            <Route path="" element={<RoutingMachine />} />
            <Route path="" element={<Booking />} />
            <Route path="booking-order" element={<BookingOrder />} />
            {/* // */}
            {/* IOTChargingSystem */}
            <Route path="iot-chargingsystem" element={<IOTChargingSystem />} />
            {/* // */}
            {/* Pay */}
            <Route path="Payment" element={<PaymentPage />} />
            <Route path="Pay" element={<Pay />} />
            {/* reset password*/}
            <Route path="reset-password" element={<ResetPassword />} />
            <Route path="confirm-email" element={<ConfirmEmail />} />

            {/* // */}
          </Route>
          {/* Demo Charge */}
          <Route path="station-list" element={<StationList />} />
          <Route path="station-list/:stationID/posts" element={<ChargingPostList />} />
          <Route path="station-list/:stationID/posts/:postID/connector" element={<ConnectorList />} />
          <Route path="station-list/:stationID/posts/:postID/connector/:connectorID/session" element={<Session />} />

          {/* Payment method selection */}
          <Route path="payment-method/:sessionId" element={<PaymentOptionPage />} />


          <Route path="session/:connectorID" element={<Session />} />

          {/* // */}
          <Route path="payment-status/success" element={<Success />} />
          <Route path="payment-status/failed" element={<Fail />} />
          <Route path="payment-status/error" element={<Error />} />
          <Route path="payment-status/invalid" element={<Invalid />} />

          {/* Admin Routes */}

          <Route path="/admin" element={<AdminPrivateRoute><AdminLayout /></AdminPrivateRoute>}>
            <Route index element={<AdminStations />} />
            <Route path="station" element={<AdminStations />} />

            <Route path="staff" element={<AdminStaff />} />
            <Route path="admin-reportcontainer" element={<AdminReportContainer />} />

            <Route path="map-station" element={<AdminMapStation />} />
            <Route path="admin-session" element={<AdminSession />}>
              <Route path=":stationID/posts" element={<ChargingPostList />} />
              <Route path=":stationID/posts/:postID/connector" element={<ConnectorList />} />
              <Route path=":stationID/posts/:postID/connector/:connectorID/session" element={<Session />} />
            </Route>
            <Route path="admin-map" element={<AdminStationMap />} />
            <Route path="admin-feedback" element={<AdminFeedbackPage />} />

            <Route path="vehicles" element={<AdminVehicles />} />
            <Route path="users" element={<AdminUser />} />
            <Route path="vouchers" element={<AdminVouchers />} />
            <Route path="system-configuration" element={<SystemConfigEditor />} />
            <Route path="settings" element={<AdminSettings />} />
            <Route path="station/:stationId" element={<AdminStationDetail />} />
            <Route path="stations/:stationId/posts/:postId/connectors" element={<AdminConnector />} />
            <Route path="revenue-statistics" element={<RevenueStatistics />} />
            <Route path="transaction-history" element={<TransactionHistory />} />
            <Route path="/admin/station/:stationId" element={<AdminStationDetail />} />
            <Route path="/admin/stations/:stationId/posts/:postId/connectors" element={<AdminConnector />} />


          </Route>
          {/* Staff Routes */}
          <Route path="/staff" element={<StaffPrivateRoute><StaffLayout /></StaffPrivateRoute>}>
            <Route index element={<StaffStation />} />
            <Route path="stations" element={<StaffStation />} />
            <Route path="staff-report" element={<StaffReport />} />
            <Route path="/staff/station/:stationId" element={<StaffStationDetail />} />
            <Route path="/staff/stations/:stationId/posts/:postId/connectors" element={<StaffConnector />} />
            <Route path="/staff/confirm-payment-offline" element={<ConfirmPaymentOffline />} />
            <Route path="/staff/booking-order" element={<StaffBookingOrder />} />
          </Route>

        </Routes>
        <NotificationBubble />

      </BrowserRouter>
    </NotificationProvider>

  );
}

