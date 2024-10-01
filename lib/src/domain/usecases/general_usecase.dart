abstract class IUseCase<I, O> {
  O execute(I request);
}
