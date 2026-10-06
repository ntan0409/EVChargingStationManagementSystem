using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Common.DTOs.VoucherDto
{
    public class VoucherCreateDto
    {
        public string Name { get; set; }
        public string? Description { get; set; }
        public int RequiredPoints { get; set; }
        public decimal Value { get; set; }
        public string VoucherType { get; set; }
        public DateTime ValidFrom { get; set; }
        public DateTime ValidTo { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
