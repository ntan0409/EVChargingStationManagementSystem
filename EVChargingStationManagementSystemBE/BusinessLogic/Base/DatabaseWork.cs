using Common;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace BusinessLogic.Base;

public static class DatabaseWork
{
    // Serialize state transitions, including duplicate callbacks, without schema changes.
    // Each action re-reads its state on retry; no external payment is performed here.
    public static async Task<IServiceResult> Write(EVCSMSContext db, Func<Task<IServiceResult>> action)
    {
        try
        {
            return await db.Database.CreateExecutionStrategy().ExecuteAsync(async () =>
            {
                db.ChangeTracker.Clear();
                await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
                var result = await action();
                if (result.Status == Const.SUCCESS_UPDATE_CODE)
                    await transaction.CommitAsync();
                else
                    await transaction.RollbackAsync();
                return result;
            });
        }
        catch
        {
            return new ServiceResult(Const.ERROR_EXCEPTION,
                "Không thể xác nhận thao tác với máy chủ. Kiểm tra trạng thái trước khi thử lại.");
        }
    }
}
