import Combine
import Foundation

struct PokemonRepository {

    func loadPokemons() -> AnyPublisher<[PokemonModel], Error> {
        let url = URL(string: "https:pokeapi.co/api/v2/pokemon?limit=151")
        let publisher = URLSession.shared.dataTaskPublisher(for: url!)
        let repoPublisher = publisher
            .map(\.data)
            .decode(type: PokemonListApiResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .flatMap { loadPokemon(entries: $0) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        return repoPublisher
    }

    func loadPokemon(entries: [PokemonApiResponse]) -> AnyPublisher<[PokemonModel], Error> {
        entries.publisher
            .flatMap { pokemon in
                loadPokemonDetail(for: pokemon)
            }
            .collect()
            .sort { $0.id < $1.id }
            .eraseToAnyPublisher()
    }

    func loadPokemonDetail(for pokemon: PokemonApiResponse) -> AnyPublisher<PokemonModel, Error> {
        let url = URL(string: pokemon.url)
        let publisher = URLSession.shared.dataTaskPublisher(for: url!)
        let repoPublisher = publisher
            .map(\.data)
            .decode(type: PokemonDetailApiResponse.self, decoder: JSONDecoder())
            .map { pokemonDetail in
                PokemonModel(id: pokemonDetail.id, name: pokemon.name, imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(pokemonDetail.id).png")
            }
            .eraseToAnyPublisher()
        return repoPublisher
    }
}

struct PokemonListApiResponse: Decodable {
    let results: [PokemonApiResponse]
}

struct PokemonApiResponse: Decodable {
    let name: String
    let url: String
}

struct PokemonDetailApiResponse: Decodable {
    let id: Int
}

struct PokemonModel: Hashable {
    let id: Int
    let name: String
    let imageUrl: String
}

extension Publisher where Output: Sequence {
    typealias Sorter = (Output.Element, Output.Element) -> Bool

    func sort(
        by sorter: @escaping Sorter
    ) -> Publishers.Map<Self, [Output.Element]> {
        map { sequence in
            sequence.sorted(by: sorter)
        }
    }
}
