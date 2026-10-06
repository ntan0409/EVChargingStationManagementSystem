namespace Common.DTOs.SystemConfigurationDto
{
    public class SystemConfigurationUpdateDto
    {
        public decimal? MinValue { get; set; }
        public decimal? MaxValue { get; set; }
        public DateTime? EffectedDateFrom { get; set; }
        public DateTime? EffectedDateTo { get; set; }
    }
}
