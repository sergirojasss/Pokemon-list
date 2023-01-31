import Combine
import SwiftUI

struct ContentView: View {
    @ObservedObject internal var viewModel: ContentView.ViewModel

    var body: some View {
        VStack {
            List {
                ForEach(viewModel.characters, id: \.self) { character in
                    Text(character.name)
                        .frame(maxWidth: .infinity, alignment: .center)
                    AsyncImage(url: URL(string: character.imageUrl), content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 100)
                        Divider()
                    }, placeholder: {
                        ProgressView().frame(width: 300, height: 100, alignment: .center)
                        Divider()
                    })
                    .listRowSeparator(.hidden)
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

extension ContentView {
    internal class ViewModel: ObservableObject {
        @Published internal var characters: [PokemonModel] = []
        private var cancellable: AnyCancellable?

        internal func loadData() {
            cancellable = PokemonRepository().loadPokemons().sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                case .finished:
                    print("success")
                }
            } receiveValue: { value in
                self.characters = value
            }
        }
    }
}
