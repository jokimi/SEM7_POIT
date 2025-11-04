using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

namespace BSTU.Results.Collection
{
    public class ResultsCollectionService : IResultsCollectionService
    {
        private readonly string _filePath = "results.json";
        private readonly object _fileLock = new object();
        private Dictionary<int, string> _results;
        private int _nextId = 1;

        public ResultsCollectionService()
        {
            LoadData();
        }

        private void LoadData()
        {
            lock (_fileLock)
            {
                if (File.Exists(_filePath))
                {
                    var json = File.ReadAllText(_filePath);
                    if (!string.IsNullOrEmpty(json))
                    {
                        _results = JsonSerializer.Deserialize<Dictionary<int, string>>(json);
                        _nextId = _results.Any() ? _results.Keys.Max() + 1 : 1;
                    }
                    else
                    {
                        _results = new Dictionary<int, string>();
                    }
                }
                else
                {
                    _results = new Dictionary<int, string>();
                }
            }
        }

        private void SaveData()
        {
            lock (_fileLock)
            {
                var json = JsonSerializer.Serialize(_results, new JsonSerializerOptions
                {
                    WriteIndented = true
                });
                File.WriteAllText(_filePath, json);
            }
        }

        public async Task<IEnumerable<KeyValuePair<int, string>>> GetAllAsync()
        {
            return await Task.FromResult(_results.AsEnumerable());
        }

        public async Task<string> GetByIdAsync(int id)
        {
            return await Task.FromResult(_results.ContainsKey(id) ? _results[id] : null);
        }

        public async Task<KeyValuePair<int, string>> CreateAsync(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
                throw new ArgumentException("Value cannot be empty");

            var newItem = new KeyValuePair<int, string>(_nextId, value);
            _results.Add(_nextId, value);
            _nextId++;

            SaveData();

            return await Task.FromResult(newItem);
        }

        public async Task<KeyValuePair<int, string>> UpdateAsync(int id, string value)
        {
            if (string.IsNullOrWhiteSpace(value))
                throw new ArgumentException("Value cannot be empty");

            if (!_results.ContainsKey(id))
                throw new KeyNotFoundException($"Item with id {id} not found");

            _results[id] = value;
            SaveData();

            return await Task.FromResult(new KeyValuePair<int, string>(id, value));
        }

        public async Task<KeyValuePair<int, string>> DeleteAsync(int id)
        {
            if (!_results.ContainsKey(id))
                throw new KeyNotFoundException($"Item with id {id} not found");

            var deletedItem = new KeyValuePair<int, string>(id, _results[id]);
            _results.Remove(id);
            SaveData();

            return await Task.FromResult(deletedItem);
        }

        public async Task<bool> ExistsAsync(int id)
        {
            return await Task.FromResult(_results.ContainsKey(id));
        }
    }
}