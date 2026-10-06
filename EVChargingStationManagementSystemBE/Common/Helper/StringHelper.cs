namespace Common.Helper
{
    public static class StringHelper
    {
        public static bool HasValue(this string? str)
        {
            return !string.IsNullOrWhiteSpace(str);
        }
    }
}
