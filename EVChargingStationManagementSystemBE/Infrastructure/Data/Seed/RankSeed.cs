using Infrastructure.Models;

namespace Infrastructure.Data.Seed
{
    public static class RankSeed
    {
        public static List<Ranking> GetRankings()
        {
            return [
                new (){
                    Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    RankName = "Gold",
                    MinPoints = 1,
                    DiscountPercentage = 1,
                    Description = "string"
                }
                ];
        }
    }
}
