using System.Collections.Generic;
using System.Threading.Tasks;

namespace BSTU.Results.Collection
{
    public interface IResultsCollectionService
    {
        Task<IEnumerable<KeyValuePair<int, string>>> GetAllAsync();
        Task<string> GetByIdAsync(int id);
        Task<KeyValuePair<int, string>> CreateAsync(string value);
        Task<KeyValuePair<int, string>> UpdateAsync(int id, string value);
        Task<KeyValuePair<int, string>> DeleteAsync(int id);
        Task<bool> ExistsAsync(int id);
    }
}