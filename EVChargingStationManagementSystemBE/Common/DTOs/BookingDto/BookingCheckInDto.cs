using System;
using System.ComponentModel.DataAnnotations;

namespace Common.DTOs.BookingDto
{
    public class BookingCheckInDto
    {
        [Required(ErrorMessage = " Mã check in phải được nhập ")]
        public string CheckInCode { get; set; }

    }
}
