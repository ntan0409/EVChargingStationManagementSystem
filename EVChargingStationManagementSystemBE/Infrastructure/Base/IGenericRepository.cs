using System.Linq.Expressions;

namespace Infrastructure.Base
{
    public interface IGenericRepository<T> where T : class
    {
        Task<List<T>> GetAllAsync(
            Expression<Func<T, bool>>? predicate = null,
            Func<IQueryable<T>, IQueryable<T>>? include = null,
            Func<IQueryable<T>, IOrderedQueryable<T>>? orderBy = null,
            bool asNoTracking = true
        );

        IQueryable<T> GetQueryable();

        Task<T> GetByIdAsync(Guid id);

        Task<T?> GetByIdAsync(
            Expression<Func<T, bool>> predicate,
            Func<IQueryable<T>, IQueryable<T>>? include = null,
            bool asNoTracking = true
        );

        Task CreateAsync(T entity);

        Task BulkCreateAsync(IEnumerable<T> entities);

        Task RemoveAsync(T entity);

        void PrepareCreate(T entity);

        void PrepareUpdate(T entity);

        void PrepareRemove(T entity);

        int Save();

        Task<int> SaveAsync();
    }
}
