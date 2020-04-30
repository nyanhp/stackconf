using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Api.Classes;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RestaurantController : ControllerBase
    {
        // GET: api/Restaurant
        [HttpGet]
        public IEnumerable<Restaurant> Get()
        {
            return RestaurantsDb.Restaurants;
        }

        // GET: api/Restaurant/5
        [HttpGet("{id}", Name = "Get")]
        public Restaurant Get(int id)
        {
            return RestaurantsDb.Restaurants.First(res => res.Id == id);
        }

        // POST: api/Restaurant
        [HttpPost]
        public void Post([FromBody] Restaurant restaurant)
        {
            var id = RestaurantsDb.Restaurants.Max(id => restaurant.Id);
            restaurant.Id = id + 1;
            RestaurantsDb.Restaurants.Add(restaurant) ;
        }

        // PUT: api/Restaurant/5
        [HttpPut("{id}")]
        public void Put(int id, Restaurant restaurant)
        {
            var localRestraurant = RestaurantsDb.Restaurants.First(res => res.Id == id);
            localRestraurant.Name = restaurant.Name;
            localRestraurant.Cuisine = restaurant.Cuisine;
        }

        // DELETE: api/ApiWithActions/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
            RestaurantsDb.Restaurants.Remove(RestaurantsDb.Restaurants.First(res => res.Id == id));
        }
    }
}
