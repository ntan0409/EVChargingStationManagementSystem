using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BusinessLogic.IServices
{
    public interface ICheckInCodeService
    {
        Task<string> GenerateUniqueCodeAsync();
    }
}
