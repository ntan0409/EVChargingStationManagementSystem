namespace Common.DTOs.VoucherDto
{
    public class VoucherUpdateDto
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public int? RequiredPoints { get; set; }
        public decimal? Value { get; set; }
        public string? VoucherType { get; set; }
        public DateTime? ValidFrom { get; set; }
        public DateTime? ValidTo { get; set; }
        public bool? IsActive { get; set; }
    }
}
