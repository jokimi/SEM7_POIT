using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using BSTU.Results.Collection;
using REST01.Models;

namespace REST01.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ResultsController : ControllerBase
    {
        private readonly IResultsCollectionService _resultsService;

        public ResultsController(IResultsCollectionService resultsService)
        {
            _resultsService = resultsService;
        }

        [HttpGet]
        [Authorize(Roles = "READER,WRITER")]
        public async Task<ActionResult<IEnumerable<KeyValuePair<int, string>>>> Get()
        {
            var results = await _resultsService.GetAllAsync();
            var resultsList = results.ToList();

            if (!resultsList.Any())
            {
                return NoContent();
            }

            return Ok(resultsList);
        }

        [HttpGet("{id:int}")]
        [Authorize(Roles = "READER,WRITER")]
        public async Task<ActionResult<string>> Get(int id)
        {
            var result = await _resultsService.GetByIdAsync(id);
            if (result == null)
            {
                return NotFound();
            }

            return Ok(result);
        }

        [HttpPost]
        [Authorize(Roles = "WRITER")]
        public async Task<ActionResult<KeyValuePair<int, string>>> Post([FromBody] CreateResultRequest request)
        {
            if (request?.Value == null)
            {
                return BadRequest("Value is required");
            }

            try
            {
                var created = await _resultsService.CreateAsync(request.Value);
                return CreatedAtAction(nameof(Get), new { id = created.Key }, created);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "WRITER")]
        public async Task<ActionResult<KeyValuePair<int, string>>> Put(int id, [FromBody] UpdateResultRequest request)
        {
            if (request?.Value == null)
            {
                return BadRequest("Value is required");
            }

            try
            {
                var updated = await _resultsService.UpdateAsync(id, request.Value);
                return Ok(updated);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpDelete("{id:int}")]
        [Authorize(Roles = "WRITER")]
        public async Task<ActionResult<KeyValuePair<int, string>>> Delete(int id)
        {
            try
            {
                var deleted = await _resultsService.DeleteAsync(id);
                return Ok(deleted);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }

        [HttpPost("SignIn")]
        [AllowAnonymous]
        public async Task<ActionResult<string>> SignIn([FromBody] SignInRequest request)
        {
            return BadRequest("Use AuthController for authentication");
        }
    }
}